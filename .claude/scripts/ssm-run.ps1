<#
.SYNOPSIS
    Gửi lệnh shell tới EC2 qua SSM Run Command (không cần SSH, không mở port 22).

.DESCRIPTION
    Wrapper quanh `aws ssm send-command` để tránh lỗi escaping của PowerShell:
    payload JSON được dựng bằng ConvertTo-Json (tự escape đúng chuẩn), ghi ra
    file tạm rồi truyền qua --cli-input-json, sau đó poll tới khi lệnh kết thúc
    và in stdout/stderr.

    Lý do tồn tại: việc nhúng JSON nhiều dòng vào command line PowerShell liên
    tục hỏng vì dấu `\` và `"` — script này loại bỏ hoàn toàn vấn đề đó.

.PARAMETER InstanceId
    EC2 instance ID (vd i-01c55680c83c267e7).

.PARAMETER Commands
    Mảng các lệnh shell, chạy tuần tự trong cùng một shell trên instance.
    Viết theo cú pháp bash (script chạy trên Ubuntu, không phải PowerShell).

    LƯU Ý: khi gọi bằng `pwsh -File`, PowerShell không truyền được mảng qua
    command line (mọi thứ thành 1 string). Vì vậy với nhiều lệnh, hoặc dùng
    `-ScriptFile`, hoặc gọi `& .claude/scripts/ssm-run.ps1 -Commands 'a','b'`
    từ trong một session PowerShell.

.PARAMETER ScriptFile
    Đường dẫn file script bash trên máy bạn (vd .claude/tmp/check-vm1.sh).
    Nội dung file được gửi nguyên khối làm MỘT lệnh → không phải escape gì,
    hỗ trợ script nhiều dòng. Đây là cách khuyến nghị cho lệnh phức tạp.

.PARAMETER Region
    AWS region, mặc định ap-southeast-1 (theo luật repo).

.PARAMETER TimeoutSeconds
    Thời gian chờ tối đa, mặc định 180 giây.

.EXAMPLE
    pwsh -File .claude/scripts/ssm-run.ps1 -InstanceId i-01c55680c83c267e7 -ScriptFile .claude/tmp/check-vm1.sh

.EXAMPLE
    & .claude/scripts/ssm-run.ps1 -InstanceId i-01c55680c83c267e7 -Commands 'docker ps', 'systemctl is-active docker'
#>
param(
    [Parameter(Mandatory = $true)][string]$InstanceId,
    [Parameter(Mandatory = $true, ParameterSetName = 'Inline')][string[]]$Commands,
    [Parameter(Mandatory = $true, ParameterSetName = 'File')][string]$ScriptFile,
    [string]$Region = 'ap-southeast-1',
    [int]$TimeoutSeconds = 180
)

$ErrorActionPreference = 'Stop'

if ($PSCmdlet.ParameterSetName -eq 'File') {
    if (-not (Test-Path $ScriptFile)) { throw "Không tìm thấy script: $ScriptFile" }
    # Gửi cả file như MỘT lệnh: AWS-RunShellScript chạy trong cùng shell nên
    # script nhiều dòng hoạt động bình thường, không cần escape.
    # BẮT BUỘC chuẩn hoá CRLF -> LF: file soạn trên Windows có \r\n sẽ làm shebang
    # thành "#!/usr/bin/env bash\r" -> lỗi "/usr/bin/env: 'bash\r': No such file".
    $raw = (Get-Content -Path $ScriptFile -Raw) -replace "`r`n", "`n" -replace "`r", "`n"
    $Commands = @($raw)
}

$ErrorActionPreference = 'Stop'

# Dựng payload bằng ConvertTo-Json: không cần escape thủ công
$payload = @{
    DocumentName = 'AWS-RunShellScript'
    Parameters   = @{ commands = $Commands }
} | ConvertTo-Json -Depth 6 -Compress

$tmp = Join-Path $env:TEMP ("ssm-run-{0}.json" -f ([guid]::NewGuid().ToString('N').Substring(0, 8)))
# UTF-8 KHÔNG BOM: AWS CLI từ chối file có BOM
[System.IO.File]::WriteAllText($tmp, $payload, [System.Text.UTF8Encoding]::new($false))

try {
    $fileUri = 'file://' + ($tmp -replace '\\', '/')

    $cmdId = aws ssm send-command `
        --instance-ids $InstanceId `
        --region $Region `
        --cli-input-json $fileUri `
        --query 'Command.CommandId' --output text

    if (-not $cmdId) { throw "Không lấy được CommandId (kiểm tra instance id / quyền ssm:SendCommand)" }

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $status = 'Pending'
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 3
        $inv = aws ssm get-command-invocation `
            --command-id $cmdId --instance-id $InstanceId --region $Region `
            --output json 2>$null | ConvertFrom-Json
        if (-not $inv) { continue }
        $status = $inv.Status
        if ($status -in @('Success', 'Failed', 'Cancelled', 'TimedOut')) { break }
    }

    Write-Host "--- CommandId: $cmdId | Status: $status ---"
    if ($inv.StandardOutputContent) { Write-Host $inv.StandardOutputContent.TrimEnd() }
    if ($inv.StandardErrorContent) { Write-Host '--- STDERR ---'; Write-Host $inv.StandardErrorContent.TrimEnd() }

    if ($status -ne 'Success') { exit 1 }
}
finally {
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
}
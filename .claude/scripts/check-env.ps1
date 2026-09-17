# check-env.ps1 — Kiểm tra toolchain DevOps cho dự án CTFd-AWS
# Chạy: pwsh -File .claude/scripts/check-env.ps1
$ErrorActionPreference = "Continue"
function Test-Tool($name, $cmd, $args = "--version") {
    try {
        $v = (Invoke-Expression "$cmd $args 2>`$null" | Select-Object -First 1)
        if ($LASTEXITCODE -eq 0 -or $v) {
            Write-Host "  [OK]   $name : $v" -ForegroundColor Green
            return $true
        }
    } catch {}
    Write-Host "  [MISS] $name — chua cai" -ForegroundColor Yellow
    return $false
}

Write-Host "`n=== Toolchain check — ctfd-platform-2026 ===`n"
$r = @{}
$r.git       = Test-Tool "git" "git"
$r.aws       = Test-Tool "AWS CLI v2" "aws"
$r.terraform = Test-Tool "Terraform" "terraform"
$r.docker    = Test-Tool "Docker" "docker"
$r.python    = Test-Tool "Python 3" "python"
$r.node      = Test-Tool "Node.js (optional)" "node"

Write-Host ""
foreach ($t in @("ansible-playbook","ansible-lint","yamllint","pre-commit","tflint","session-manager-plugin")) {
    $r.$t = Test-Tool $t $t
}

Write-Host "`n=== Ket qua ==="
$miss = $r.GetEnumerator() | Where-Object { -not $_.Value } | Select-Object -ExpandProperty Key
if ($miss) {
    Write-Host "Thieu: $($miss -join ', ')" -ForegroundColor Yellow
    Write-Host "Cai dat nhanh: pwsh -File .claude/scripts/setup-dev-env.ps1"
    Write-Host "Luu y: terraform/awscli/docker ca bang tay (winget/scoop) — script khong tu dong cai cac tool nay."
} else {
    Write-Host "Du toolchain. San sang deploy!" -ForegroundColor Green
}

# AWS identity (neu co)
if ($r.aws) {
    Write-Host "`n=== AWS identity ==="
    aws sts get-caller-identity --region ap-southeast-1 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "Chua cau hinh AWS credentials (aws configure / SSO)" -ForegroundColor Yellow }
}

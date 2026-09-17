# test-hooks.ps1 — Kiểm thử 5 hook với payload stdin mẫu
# Dùng: pwsh -File .claude/scripts/test-hooks.ps1
$ErrorActionPreference = "Continue"
function Invoke-Hook($file, $json) {
    $json | python ".claude/hooks/$file"
    return $LASTEXITCODE
}

$pass = 0; $fail = 0
function Check($desc, $expectedBlock, $output, $exitCode) {
    $blocked = $output -match '"decision"\s*:\s*"block"'
    $ok = if ($expectedBlock) { $blocked } else { -not $blocked }
    if ($ok) { $script:pass++; Write-Host "  [PASS] $desc" -ForegroundColor Green }
    else    { $script:fail++; Write-Host "  [FAIL] $desc" -ForegroundColor Red; Write-Host "         out: $($output | Select-Object -First 1)" }
}

Write-Host "=== protect_secrets.py ==="
$o = '{"tool_name":"Read","tool_input":{"file_path":"terraform/aws/terraform.tfvars"}}' | python .claude/hooks/protect_secrets.py
Check "Read tfvars -> BLOCK" $true $o $LASTEXITCODE
$o = '{"tool_name":"Bash","tool_input":{"command":"cat scripts/mtls_certs/ca-key.pem"}}' | python .claude/hooks/protect_secrets.py
Check "cat ca-key.pem -> BLOCK" $true $o $LASTEXITCODE
$o = '{"tool_name":"Bash","tool_input":{"command":"terraform plan"}}' | python .claude/hooks/protect_secrets.py
Check "terraform plan -> ALLOW" $false $o $LASTEXITCODE
$o = '{"tool_name":"Bash","tool_input":{"command":"echo secret_frp_token_2026"}}' | python .claude/hooks/protect_secrets.py
Check "echo FRP token literal -> BLOCK" $true $o $LASTEXITCODE

Write-Host "`n=== guard_dangerous_ops.py ==="
$o = '{"tool_name":"Bash","tool_input":{"command":"terraform -chdir=terraform/aws destroy"}}' | python .claude/hooks/guard_dangerous_ops.py
Check "terraform destroy -> BLOCK" $true $o $LASTEXITCODE
$o = '{"tool_name":"Bash","tool_input":{"command":"aws ec2 terminate-instances --instance-ids i-123"}}' | python .claude/hooks/guard_dangerous_ops.py
Check "terminate-instances -> BLOCK" $true $o $LASTEXITCODE
$o = '{"tool_name":"Bash","tool_input":{"command":"terraform apply -auto-approve"}}' | python .claude/hooks/guard_dangerous_ops.py
Check "apply -auto-approve -> BLOCK (bat buoc review)" $true $o $LASTEXITCODE
$o = '{"tool_name":"Bash","tool_input":{"command":"terraform plan"}}' | python .claude/hooks/guard_dangerous_ops.py
Check "terraform plan -> ALLOW" $false $o $LASTEXITCODE

Write-Host "`n=== session_context.py ==="
$o = '{"source":"startup"}' | python .claude/hooks/session_context.py
if ($o -match 'additionalContext' -and $o -match 'CyberKnight') { $pass++; Write-Host "  [PASS] SessionStart context" -ForegroundColor Green }
else { $fail++; Write-Host "  [FAIL] SessionStart context: $o" -ForegroundColor Red }

Write-Host "`n=== log_activity.py ==="
'{"tool_name":"Bash","tool_input":{"command":"terraform plan"}}' | python .claude/hooks/log_activity.py
$logs = Get-ChildItem .claude/logs/activity-*.jsonl -ErrorAction SilentlyContinue
if ($logs) { $pass++; Write-Host "  [PASS] log written: $($logs.Name)" -ForegroundColor Green }
else { $fail++; Write-Host "  [FAIL] no log file" -ForegroundColor Red }

Write-Host "`n=== tf_format_check.py (chỉ chạy nếu có terraform) ==="
"{}" | python .claude/hooks/tf_format_check.py
if ($LASTEXITCODE -eq 0) { $pass++; Write-Host "  [PASS] exit 0 (non-blocking)" -ForegroundColor Green } else { $fail++ }

Write-Host "`n=== Ket qua: $pass pass / $fail fail ==="
if ($fail -gt 0) { exit 1 }

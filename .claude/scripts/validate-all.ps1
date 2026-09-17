# validate-all.ps1 — Validate offline toàn bộ IaC + hooks (không đụng AWS)
# Dùng: pwsh -File .claude/scripts/validate-all.ps1
$ErrorActionPreference = "Continue"
$results = @()

function Add-Result($name, $ok, $note = "") {
    $script:results += [pscustomobject]@{ Check = $name; Pass = $ok; Note = $note }
}

# 1) Terraform fmt + validate (cả aws & gcp)
# NOTE: dùng Push-Location thay vì -chdir=$d — PowerShell không expand biến
# trong token "-chdir=$d" ở mọi ngữ cảnh, gây "Error handling -chdir option".
foreach ($d in @("terraform/aws", "terraform/gcp")) {
    if (Test-Path "$d/variables.tf") {
        Push-Location $d
        try {
            $fmtOut = terraform fmt -check -recursive 2>&1
            $fmtCode = $LASTEXITCODE
            $valOut = terraform validate 2>&1
            $valCode = $LASTEXITCODE
        } finally { Pop-Location }
        Add-Result "terraform fmt ($d)" ($fmtCode -eq 0) "fix: terraform -chdir=$d fmt"
        if ($valCode -ne 0 -and (($valOut -join ' ') -match "provider isn't available|Missing required provider")) {
            Add-Result "terraform validate ($d)" $null "cần terraform -chdir=$d init trước"
        } else {
            $valBrief = (($valOut | Where-Object { $_ -match 'Error|Warning' } | Select-Object -First 2) -join ' | ')
            Add-Result "terraform validate ($d)" ($valCode -eq 0) $valBrief
        }
    }
}

# 2) YAML lint
if (Get-Command yamllint -ErrorAction SilentlyContinue) {
    $yOut = yamllint -d relaxed ansible/ challenges/k8s/ 2>&1
    Add-Result "yamllint (ansible + k8s)" ($LASTEXITCODE -eq 0) (($yOut | Select-Object -First 3) -join ' | ')
} else { Add-Result "yamllint" $null "chưa cài: pip install --user yamllint" }

# 3) Ansible lint + syntax
if (Get-Command ansible-lint -ErrorAction SilentlyContinue) {
    ansible-lint ansible/ *>$null
    Add-Result "ansible-lint" ($LASTEXITCODE -eq 0)
} else { Add-Result "ansible-lint" $null "chưa cài: pip install --user ansible-lint" }
if (Get-Command ansible-playbook -ErrorAction SilentlyContinue) {
    foreach ($pb in @("ansible/aws/vm1_web.yml", "ansible/common/vm1_web.yml", "ansible/common/vm2_challenge.yml", "ansible/common/mtls_setup.yml")) {
        if (Test-Path $pb) {
            ansible-playbook --syntax-check $pb *>$null
            Add-Result "syntax-check $pb" ($LASTEXITCODE -eq 0)
        }
    }
}

# 4) Python hooks compile (PowerShell không expand wildcard cho native exe)
$hookFiles = Get-ChildItem .claude/hooks -Filter *.py -ErrorAction SilentlyContinue
if ($hookFiles) {
    python -m py_compile @($hookFiles.FullName) *>$null
    Add-Result "py_compile .claude/hooks" ($LASTEXITCODE -eq 0)
} else { Add-Result "py_compile .claude/hooks" $false "không tìm thấy hooks" }

# 5) settings.json là JSON hợp lệ
try {
    Get-Content .claude/settings.json -Raw | ConvertFrom-Json *>$null
    Add-Result "settings.json parse" $true
} catch { Add-Result "settings.json parse" $false $_.Exception.Message }

# Báo cáo
Write-Host "`n=== Validation report ==="
$results | Format-Table -AutoSize
$failed = $results | Where-Object { $_.Pass -eq $false }
if ($failed) { Write-Host "FAIL: $($failed.Count) mục — xem cột Note." -ForegroundColor Red }
else { Write-Host "Tất cả PASS (hoặc tool chưa cài = skipped)." -ForegroundColor Green }

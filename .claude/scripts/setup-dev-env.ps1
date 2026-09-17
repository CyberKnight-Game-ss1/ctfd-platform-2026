# setup-dev-env.ps1 — Bootstrap toolchain DevOps (Windows / PowerShell 7)
# Dùng: pwsh -File .claude/scripts/setup-dev-env.ps1 [-SkipPip]
param([switch]$SkipPip)

$ErrorActionPreference = "Continue"
Write-Host "=== Setup dev env — ctfd-platform-2026 ===`n"

# 1) Python packages (an toàn nhất: pip --user trên Windows)
if (-not $SkipPip) {
    $pkgs = @("ansible", "ansible-lint", "yamllint", "pre-commit")
    foreach ($p in $pkgs) {
        Write-Host ">> pip install --user $p"
        python -m pip install --user --quiet --upgrade $p
        if ($LASTEXITCODE -ne 0) {
            Write-Host "   ! Loi cai $p — thử manual: python -m pip install --user $p" -ForegroundColor Yellow
        }
    }
    # Đảm bảo Python user Scripts nằm trong PATH của session
    $userScripts = python -c "import site; print(site.USER_BASE)" 2>$null
    if ($userScripts) {
        $env:PATH = "$env:PATH;$userScripts\Scripts;$userScripts\bin"
    }
}

# 2) pre-commit git hook
if (Get-Command pre-commit -ErrorAction SilentlyContinue) {
    Write-Host "`n>> pre-commit install"
    pre-commit install
    Write-Host "   (chay lan dau: pre-commit run --all-files)"
} else {
    Write-Host "`n! pre-commit chua co — chay lai script khong -SkipPip" -ForegroundColor Yellow
}

# 3) Hướng dẫn các tool hệ thống (không tự cài — để user chủ động)
Write-Host @"

=== Tool he thong (tu cai bang winget/scoop neu thieu) ===
  winget install Hashicorp.Terraform      # terraform
  winget install Amazon.AWSCLI            # aws cli v2
  winget install Docker.DockerDesktop     # docker
  # Session Manager plugin (bat buoc de aws ssm start-session):
  # https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

=== Kiem tra lai ===
  pwsh -File .claude/scripts/check-env.ps1
=== Validate lan dau ===
  pwsh -File .claude/scripts/validate-all.ps1
"@

#!/usr/bin/env bash
# setup-dev-env.sh — Bootstrap toolchain DevOps (Linux/macOS)
# Dùng: bash .claude/scripts/setup-dev-env.sh
set -uo pipefail

echo "=== Setup dev env — ctfd-platform-2026 ==="

echo ">> pip install (user) ansible ansible-lint yamllint pre-commit"
python3 -m pip install --user --upgrade ansible ansible-lint yamllint pre-commit

# Đưa user bin vào PATH cho session hiện tại
USER_BIN="$(python3 -c 'import site; print(site.USER_BASE)')/bin"
export PATH="$PATH:$USER_BIN"

if command -v pre-commit >/dev/null 2>&1; then
  echo ">> pre-commit install"
  pre-commit install
  echo "   (chạy lần đầu: pre-commit run --all-files)"
fi

cat <<'EOF'

=== Tool hệ thống (cài tay nếu thiếu) ===
  Terraform:  https://developer.hashicorp.com/terraform/install
  AWS CLI v2: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
  Docker:     curl -fsSL https://get.docker.com | sh
  Session Manager plugin:
    https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

=== Kiểm tra lại ===
  bash .claude/scripts/check-env.sh   (hoặc dùng check-env.ps1 qua pwsh)
=== Validate lần đầu ===
  pwsh -File .claude/scripts/validate-all.ps1   # hoặc chạy từng lệnh bên trong
EOF

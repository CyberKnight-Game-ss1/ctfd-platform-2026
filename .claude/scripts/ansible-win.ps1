# ansible-win.ps1 — Wrapper chạy ansible-playbook trên Windows non-console (agent/CI)
#
# Ansible-core 2.21 trên Windows fail khi stdout/stdin là pipe (không phải console):
#   1) check_blocking_io()  → OSError WinError 1 "Incorrect function"
#   2) initialize_locale()  → "Ansible requires the locale encoding to be UTF-8;
#      Detected 1252" (locale.getlocale() trả code page ANSI của Windows)
# Wrapper monkeypatch 2 hàm này rồi gọi main() trực tiếp.
#
# Dùng:
#   pwsh -File .claude/scripts/ansible-win.ps1 -i ansible/aws/inventory.ini ansible/common/mtls_setup.yml
#   pwsh -File .claude/scripts/ansible-win.ps1 -i ansible/aws/inventory.ini ansible/aws/vm1_web.yml --check --diff
param([Parameter(ValueFromRemainingArguments = $true)]$AnsibleArgs)

$code = @"
import os, locale, sys
os.get_blocking = lambda fd: True                 # bypass check_blocking_io
locale.getlocale = lambda *a, **k: ('en_US', 'utf-8')  # bypass initialize_locale
from ansible.cli.playbook import main
sys.exit(main(sys.argv[1:]))
"@

# PYTHONUTF8 giữ nguyên (không sửa hành vi, chỉ bảo đảm stdio UTF-8)
$env:PYTHONUTF8 = '1'
& python -c $code @AnsibleArgs
exit $LASTEXITCODE

# Hooks — Bộ bảo vệ & tự động hoá cho agent

Hooks chạy tự động theo vòng đời công cụ của Claude Code (cấu hình trong
`.claude/settings.json` → `hooks`). Toàn bộ viết bằng **Python thuần (stdlib)** —
chạy được trên Windows/Linux/macOS, chỉ cần `python` trên PATH.

## Ma trận hook

| Hook | Event | Matcher | Hành vi | Block? |
|---|---|---|---|---|
| `protect_secrets.py` | PreToolUse | `Bash`, `Read\|Edit\|Write\|MultiEdit\|NotebookEdit` | Chặn truy cập tfvars/tfstate/pem/inventory.ini/.env + literal secret (`secret_frp_token_2026`, `CyberKnightCTF_DB_`...) | ✅ JSON `decision: block` |
| `guard_dangerous_ops.py` | PreToolUse | `Bash` | Chặn destroy-class (`terraform destroy`, `terminate-instances`, `delete-db-instance`, `s3 rb`, `DROP`, `rm -rf /`, `push --force`, `prune -a`) + chặn `apply -auto-approve` | ✅ |
| `tf_format_check.py` | PostToolUse | `Write\|Edit\|MultiEdit` khi file `.tf` | Chạy `terraform fmt -check -diff`, cảnh báo stderr | ❌ warn only |
| `log_activity.py` | PostToolUse | `Bash\|Write\|Edit\|MultiEdit\|Read` | Ghi JSONL vào `.claude/logs/activity-<YYYYMMDD>.jsonl` (gitignored) | ❌ |
| `session_context.py` | SessionStart | `startup\|resume` | Tiêm ngữ cảnh dự án ngắn vào đầu phiên | ❌ |

## Hợp đồng stdin/stdout

Hook nhận JSON trên stdin:
```json
{ "session_id": "...", "hook_event_name": "PreToolUse",
  "tool_name": "Bash", "tool_input": { "command": "..." } }
```
Trả về:
- **Block**: in `{"decision": "block", "reason": "..."}` ra stdout, exit 0 (reason hiển thị cho agent).
- **Context (SessionStart)**: `{"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "..."}}`.
- **Không làm gì**: exit 0, không stdout.

## Bypass (cho con người)

```bash
# chỉ có tác dụng trong shell hiện tại — agent không nên tự set
$env:CTFD_HOOKS_BYPASS = "1"        # PowerShell
CTFD_HOOKS_BYPASS=1 <cmd>           # bash
```
Hook tôn trọng biến này và tắt toàn bộ guard. Chỉ dùng khi bạn hiểu rủi ro.

## Test thủ công

```powershell
# protect_secrets: phải BLOCK
'{"tool_name":"Read","tool_input":{"file_path":"terraform/aws/terraform.tfvars"}}' |
  python .claude/hooks/protect_secrets.py

# guard_dangerous_ops: phải BLOCK với giải thích
'{"tool_name":"Bash","tool_input":{"command":"terraform -chdir=terraform/aws destroy"}}' |
  python .claude/hooks/guard_dangerous_ops.py

# session_context: in JSON additionalContext
'{"source":"startup"}' | python .claude/hooks/session_context.py

# log_activity: ghi 1 dòng vào .claude/logs/
'{"tool_name":"Bash","tool_input":{"command":"terraform plan"}}' |
  python .claude/hooks/log_activity.py; Get-Content .claude/logs/*.jsonl
```
Hoặc chạy tất cả: `pwsh -File .claude/scripts/test-hooks.ps1`

## Thêm hook mới

1. Tạo `hooks/<tên>.py` theo hợp đồng trên (stdlib only, luôn exit 0).
2. Đăng ký trong `.claude/settings.json` → `hooks` với event + matcher phù hợp.
3. Thêm case test vào `scripts/test-hooks.ps1`.
4. Cập nhật bảng trong README này.

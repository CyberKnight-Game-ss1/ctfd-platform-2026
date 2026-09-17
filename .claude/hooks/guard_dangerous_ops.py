#!/usr/bin/env python3
"""PreToolUse hook — Chặn các lệnh PHÁ HỦY hạ tầng AWS của cụm CTF.

Mô hình rủi ro: toàn bộ VPC/EC2/RDS/S3/SSM của CyberKnight CTF có thể bị xoá
sạch chỉ bằng một câu lệnh. Hook này là "airlock": chặn cứng, giải thích rủi ro,
và chỉ con người (chạy trong terminal riêng, không qua agent) mới vượt được.

Chặn cứng (block):
  terraform destroy | ec2 terminate-instances | rds delete-db-instance
  s3 rb / delete-bucket | ssm delete-parameter | DROP DATABASE/TABLE | rm -rf /
  git push --force | TRUNCATE | docker system prune -af (mất images challenge)

Yêu cầu xác nhận (ask):
  terraform apply ... -auto-approve  → bắt buộc user gõ xác nhận, không auto

Bypass cho con người: CTFD_HOOKS_BYPASS=1
"""
import json
import os
import re
import sys

# Windows console có thể là cp1252 — ép UTF-8 để in được tiếng Việt/emoji
for _s in (sys.stdout, sys.stderr):
    if _s and hasattr(_s, "reconfigure"):
        try:
            _s.reconfigure(encoding="utf-8")
        except Exception:
            pass

BYPASS_ENV = "CTFD_HOOKS_BYPASS"

HARD_BLOCK = [
    (r"\bterraform\s+(?:-chdir=\S+\s+)?destroy\b",
     "`terraform destroy` sẽ XÓA SẠCH hạ tầng AWS (VPC, EC2 VM1/VM2, RDS PostgreSQL, S3, SSM, EventBridge)",
     "Chỉ chạy khi dọn hạ tầng có chủ đích, sau khi snapshot RDS. Nếu thật sự cần: xin user tự chạy trong terminal."),
    (r"\baws\s+ec2\s+terminate-instances\b",
     "`terminate-instances` xoá vĩnh viễn EC2 (không thể khôi phục như stop)",
     "Dùng `aws ec2 stop-instances` nếu chỉ muốn tiết kiệm chi phí."),
    (r"\baws\s+rds\s+delete-db-instance\b",
     "`delete-db-instance` xoá RDS PostgreSQL chứa toàn bộ user/submission/score",
     "Cân nhắc `deletion_protection=true` trước thi đấu thật. Final snapshot bắt buộc trước khi xoá."),
    (r"\baws\s+s3\s+rb\b|\baws\s+s3api\s+delete-bucket\b",
     "xoá S3 bucket (PCAP + database backups)",
     "Kiểm tra `aws s3 ls` trước khi quyết định."),
    (r"\baws\s+ssm\s+delete-parameter\b",
     "xoá SSM Parameter `/ctfd/database-url` — VM1 sẽ không boot được CTFd",
     ""),
    (r"\bDROP\s+(DATABASE|TABLE|SCHEMA)\b|\bTRUNCATE\s+TABLE\b",
     "SQL DROP/TRUNCATE trên database CTFd (mất user, challenge, submission)",
     "Backup trước: `pg_dump` từ VM1 hoặc RDS snapshot."),
    (r"\brm\s+-rf\s+(/|~|\$HOME)(\s|'|\")?($|\s)",
     "`rm -rf` vào root/home — xoá hệ thống",
     ""),
    (r"\bgit\s+push\b[^;|&]*\s--force\b",
     "`git push --force` ghi đè lịch sử git dùng chung của team",
     "Dùng `--force-with-lease` và nói chuyện với team trước."),
    (r"\bdocker\s+system\s+prune\s+-a\b|\bdocker\s+rmi\s+-f\s+\$\(",
     "xoá toàn bộ Docker images (gồm images challenge đã build trên máy dev)",
     ""),
    (r"\bkill\s+-9\s+1\b|\bshutdown\b|\breboot\b",
     "shutdown/reboot hệ điều hành cục bộ",
     ""),
]

ASK = [
    (r"\bterraform\s+(?:-chdir=\S+\s+)?apply\b[^;|&]*-auto-approve",
     "`terraform apply -auto-approve` bỏ qua bước review plan",
     "Tách nhỏ: chạy `terraform plan` trước, cho user xem diff rồi mới apply."),
]


def out(payload: dict) -> None:
    print(json.dumps(payload, ensure_ascii=False))
    sys.exit(0)


def main() -> int:
    try:
        payload = json.loads(sys.stdin.read() or "{}")
    except Exception:
        return 0

    if os.environ.get(BYPASS_ENV) == "1":
        return 0

    if payload.get("tool_name") != "Bash":
        return 0

    command = (payload.get("tool_input", {}) or {}).get("command", "") or ""

    for pat, what, advice in HARD_BLOCK:
        if re.search(pat, command, re.IGNORECASE):
            out({
                "decision": "block",
                "reason": (
                    f"🚨 guard_dangerous_ops: {what}\n{advice}\n"
                    "Agent KHÔNG được tự ý chạy lệnh phá hủy. Trình bày rủi ro cho user; "
                    "nếu user đồng ý, user sẽ tự chạy lệnh trong terminal (hoặc set "
                    "CTFD_HOOKS_BYPASS=1 cho phiên này)."
                ),
            })

    for pat, what, advice in ASK:
        if re.search(pat, command, re.IGNORECASE):
            out({
                "decision": "block",
                "reason": (
                    f"⚠️ guard_dangerous_ops: {what}. {advice} "
                    "Hỏi user để xác nhận, sau đó chạy apply KHÔNG có -auto-approve để review từng bước."
                ),
            })

    return 0


if __name__ == "__main__":
    sys.exit(main())

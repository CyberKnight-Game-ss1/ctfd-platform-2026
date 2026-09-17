#!/usr/bin/env python3
"""SessionStart hook — Tiêm ngữ cảnh dự án vào đầu mỗi phiên làm việc.

Output JSON chuẩn Claude Code:
  {"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "..."}}

Giữ additionalContext ngắn (< 1k token) — chỉ tóm tắt điều agent BẮT BUỘC biết.
Chi tiết đầy đủ nằm trong CLAUDE.md và .claude/architecture/.
"""
import json
import os
import sys

# Windows console có thể là cp1252 — ép UTF-8 để in được tiếng Việt/emoji
for _s in (sys.stdout, sys.stderr):
    if _s and hasattr(_s, "reconfigure"):
        try:
            _s.reconfigure(encoding="utf-8")
        except Exception:
            pass

CONTEXT = """## CyberKnight CTFd Platform — ngữ cảnh phiên làm việc

- **Stack**: CTFd self-hosted trên AWS ap-southeast-1; Cloudflare trước; IaC = Terraform (`terraform/aws`) + Ansible (`ansible/aws`, `ansible/common`).
- **VM1** `ctf-vm1-web` (t3.medium): Nginx :80 + CTFd :8000 + Redis :6379 + FRPS + PostgreSQL container (hoặc RDS — xem architecture/03). SSH chỉ qua SSM Session Manager.
- **VM2** `ctf-vm2-challenge` (t3.small/Spot): Docker, docker-socket-proxy (loopback :2376), tcpdump PCAP, K3s + nsjail.
- **Dữ liệu**: RDS PostgreSQL 15 (`ctf-postgres`, private), SSM `/ctfd/database-url` (SecureString), S3 `ctf-storage-*` (PCAP/backup, lifecycle 7→30 ngày).
- **Lưu ý playbook**: `ansible/aws/vm1_web.yml` hiện chạy PostgreSQL container trên VM1, KHÔNG dùng RDS dù Terraform đã provision — xác nhận phương án với user trước khi deploy.
- **Tuyệt đối**: không đọc/commit tfstate|tfvars|pem|inventory.ini|ctfd_config.txt (hook sẽ chặn); không `terraform destroy`; mọi lệnh `aws` region `ap-southeast-1`.
- **Bắt đầu**: `/aws-status` để kiểm tra hạ tầng, `/aws-deploy` để triển khai end-to-end, `terraform -chdir=terraform/aws plan` để xem diff.
"""


def main() -> int:
    try:
        payload = json.loads(sys.stdin.read() or "{}")
    except Exception:
        payload = {}

    source = payload.get("source", "startup")
    ctx = CONTEXT
    if source == "resume":
        ctx = "## Phiên được resume — nhắc lại ngữ cảnh\n\n" + CONTEXT

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": ctx,
        }
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())

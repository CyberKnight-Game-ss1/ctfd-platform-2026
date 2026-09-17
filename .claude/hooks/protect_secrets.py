#!/usr/bin/env python3
"""PreToolUse hook — Bảo vệ secrets của repo CTFd.

Chặn agent:
  - Read/Edit/Write vào file nhạy cảm (tfvars, tfstate, pem/key, inventory.ini, .env...)
  - Bash cat/echo/cp các file đó, hoặc in literal secret ra terminal/stdout

Cách hoạt động: đọc JSON từ stdin (Claude Code hook contract), nếu vi phạm thì
in JSON {"decision": "block", "reason": "..."} ra stdout và exit 0.

Bypass (cho con người, không phải agent): set env CTFD_HOOKS_BYPASS=1
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

# (regex đường dẫn, lý do) — áp dụng cho Read/Edit/Write/NotebookEdit
SECRET_PATH_PATTERNS = [
    (r"\.tfvars(\.json)?$", "biến Terraform chứa password RDS (`db_password`)"),
    (r"\.tfstate", "Terraform state chứa secret dạng plaintext"),
    (r"(^|/)\.terraform(/|$)", "thư mục provider/state cục bộ của Terraform"),
    (r"scripts/mtls_certs/", "CA + private key mTLS của cụm CTF"),
    (r"\.(pem|key|crt|csr)$", "certificate / private key"),
    (r"ansible/(aws|gcp|common)/inventory\.ini$", "inventory chứa IP thật (chỉ .example được commit)"),
    (r"(^|/)\.aws(/|$)", "thư mục AWS credentials cục bộ"),
    (r"(^|/)credentials$", "file credentials"),
    (r"id_rsa", "SSH private key"),
    (r"ctfd_config\.txt$", "export cấu hình CTFd cục bộ"),
    (r"remote_docker-compose\.yml$", "export docker-compose cục bộ"),
    (r"(^|/)\.env($|\.)", "dotenv có thể chứa secret"),
]

# Literal secret thật của repo — chặn tuyệt đối kể cả trong Bash
SECRET_LITERAL_PATTERNS = [
    (r"secret_frp_token_2026", "FRP token thật của repo"),
    (r"CyberKnightCTF_DB_", "định dạng password RDS của repo"),
    (r"change_me_in_production", "SECRET_KEY mặc định trong playbook"),
]

READ_CMDS = r"(cat|echo|head|tail|less|more|strings|grep|awk|sed|cp|mv|base64|xxd|od|tee)\b"

FILE_TOOLS = {"Read", "Write", "Edit", "MultiEdit", "NotebookEdit"}


def block(reason: str) -> None:
    print(json.dumps({
        "decision": "block",
        "reason": (
            f"🛡️ protect_secrets: {reason}\n"
            "Dữ liệu này KHÔNG được đưa vào context của agent hay commit lên git. "
            "Giá trị secret chỉ nên tồn tại trong `terraform.tfvars` (local) và "
            "SSM Parameter Store `/ctfd/database-url` (SecureString). "
            "Nếu bạn (con người) thật sự cần, hãy tự chạy lệnh trong terminal riêng."
        ),
    }, ensure_ascii=False))
    sys.exit(0)


def tool_text(tool: str, tool_input: dict) -> str:
    if tool == "Bash":
        return tool_input.get("command", "") or ""
    if tool in FILE_TOOLS:
        return tool_input.get("file_path", "") or tool_input.get("notebook_path", "") or ""
    return ""


def main() -> int:
    try:
        payload = json.loads(sys.stdin.read() or "{}")
    except Exception:
        return 0  # stdin lỗi → không chặn, tránh khoá nhầm phiên làm việc

    if os.environ.get(BYPASS_ENV) == "1":
        return 0

    tool = payload.get("tool_name", "")
    text = tool_text(tool, payload.get("tool_input", {}) or {})
    if not text:
        return 0

    if tool == "Bash":
        # 1) Literal secret trong lệnh
        for pat, why in SECRET_LITERAL_PATTERNS:
            if re.search(pat, text):
                block(f"Lệnh Bash đang chứa {why}.")
        # 2) Lệnh đọc/ copy file nhạy cảm
        for pat, why in SECRET_PATH_PATTERNS:
            if re.search(READ_CMDS + r"[^;|&]*" + pat, text, re.IGNORECASE):
                block(f"Lệnh Bash đang đọc/ghi tập tin chứa {why}.")
        return 0

    if tool in FILE_TOOLS:
        p = text.replace("\\", "/")
        for pat, why in SECRET_PATH_PATTERNS:
            if re.search(pat, p, re.IGNORECASE):
                block(f"Không được phép truy cập '{p}' — đây là {why}.")
        return 0

    return 0


if __name__ == "__main__":
    sys.exit(main())

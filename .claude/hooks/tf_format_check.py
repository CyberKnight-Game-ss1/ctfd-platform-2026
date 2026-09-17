#!/usr/bin/env python3
"""PostToolUse hook — Nhắc chạy `terraform fmt` khi agent sửa file .tf.

Không bao giờ block (chỉ cảnh báo trên stderr), vì fmt là cosmetic.
Đọc JSON stdin: {tool_name, tool_input: {file_path}, tool_response: {...}}
"""
import json
import os
import subprocess
import sys

# Windows console có thể là cp1252 — ép UTF-8 cho stderr cảnh báo
for _s in (sys.stdout, sys.stderr):
    if _s and hasattr(_s, "reconfigure"):
        try:
            _s.reconfigure(encoding="utf-8")
        except Exception:
            pass


def main() -> int:
    try:
        payload = json.loads(sys.stdin.read() or "{}")
    except Exception:
        return 0

    if payload.get("tool_name") not in ("Write", "Edit", "MultiEdit"):
        return 0

    file_path = (payload.get("tool_input", {}) or {}).get("file_path", "") or ""
    if not file_path.replace("\\", "/").endswith(".tf"):
        return 0

    workdir = os.path.dirname(os.path.abspath(file_path))
    try:
        proc = subprocess.run(
            ["terraform", "fmt", "-check", "-diff", file_path],
            cwd=workdir, capture_output=True, text=True, timeout=20,
            shell=False,
        )
    except FileNotFoundError:
        return 0  # terraform không có PATH — bỏ qua im lặng
    except subprocess.TimeoutExpired:
        return 0
    except Exception:
        return 0

    if proc.returncode != 0:
        sys.stderr.write(
            "⚠️  tf_format_check: file .tf vừa sửa KHÔNG đạt `terraform fmt`.\n"
            f"{proc.stdout[:2000]}\n"
            "→ Chạy: terraform fmt terraform/aws\n"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""PostToolUse hook — Ghi nhật ký hoạt động của agent ra .claude/logs/.

Mỗi dòng là 1 JSON object (JSONL): timestamp, session, tool, input rút gọn, kết quả.
Dùng để audit "agent đã làm gì" sau mỗi phiên. Logs bị .gitignore, không commit.
Lỗi nào cũng nuốt lặng lẽ (exit 0) — logging không bao giờ làm hỏng phiên.
"""
import datetime
import json
import os
import sys

LOG_DIR_NAME = os.path.join(".claude", "logs")
MAX_SNIPPET = 300


def brief_input(tool: str, tool_input: dict) -> str:
    if not isinstance(tool_input, dict):
        return ""
    if tool == "Bash":
        s = tool_input.get("command", "") or ""
    elif tool in ("Read", "Write", "Edit", "MultiEdit", "NotebookEdit"):
        s = tool_input.get("file_path", "") or tool_input.get("notebook_path", "") or ""
    else:
        s = json.dumps(tool_input, ensure_ascii=False)
    s = s.replace("\n", " ").strip()
    return s[:MAX_SNIPPET]


def main() -> int:
    try:
        payload = json.loads(sys.stdin.read() or "{}")
        tool = payload.get("tool_name", "Unknown")
        tool_input = payload.get("tool_input", {}) or {}

        # Không log chính hoạt động trên logs/hooks (tránh vòng lặp)
        snippet = brief_input(tool, tool_input)
        if ".claude/logs" in snippet or ".claude\\logs" in snippet:
            return 0

        log_dir = os.path.join(os.getcwd(), LOG_DIR_NAME)
        os.makedirs(log_dir, exist_ok=True)
        day = datetime.datetime.now().strftime("%Y%m%d")
        entry = {
            "ts": datetime.datetime.now().isoformat(timespec="seconds"),
            "session": payload.get("session_id", "")[:12],
            "event": payload.get("hook_event_name", "PostToolUse"),
            "tool": tool,
            "input": snippet,
            "success": payload.get("tool_response", {}).get("success", True)
            if isinstance(payload.get("tool_response"), dict) else True,
        }
        path = os.path.join(log_dir, f"activity-{day}.jsonl")
        with open(path, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    except Exception:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())

# .claude/ — Trung tâm điều khiển AI Agent cho hạ tầng CTFd-AWS

Thư mục theo **chuẩn Claude Code**, dùng được cả cho agent khác (Cline/Codex) như
bộ tài liệu + guards + workflow chung. Mục tiêu: bất kỳ ai (hoặc AI nào) mở repo
cũng deploy/vận hành được cụm CTFd trên AWS mà không phá hạ tầng.

```
.claude/
├── README.md            ← bạn đang ở đây
├── settings.json        # env (region ap-southeast-1), permissions allow/ask/deny, hooks registry
├── settings.local.json.example  # template cài đặt cá nhân (bản .local.json bị gitignore)
├── CLAUDE.md → (ở repo root)    # ngữ cảnh mặc định agent
├── skills/
│   ├── README.md        # quy ước viết skill
│   ├── vendored/        # 3 repo DevOps skills CLONE TỪ UPSTREAM (xem VENDORED.md)
│   │   ├── anthropic-skills/    # official: docx/pdf/pptx/xlsx, webapp-testing, mcp-builder...
│   │   ├── superpowers/         # TDD, systematic-debugging, verification, planning + hooks mẫu
│   │   └── wshobson-agents/     # 94 plugins/202 agents/183 skills DevOps (catalog: docs/plugins.md)
│   └── ctfd-aws/        # 8 skill viết riêng cho repo này
│       ├── ctfd-aws-architecture/   # bản đồ hạ tầng + ánh xạ file ↔ resource
│       ├── ctfd-aws-deploy/         # pipeline deploy 6 bước + checklist
│       ├── ctfd-aws-terraform/      # quy ước .tf + biến + safety
│       ├── ctfd-aws-ansible/        # thứ tự playbook + idempotency + SSM
│       ├── ctfd-aws-operations/     # day-2: logs, restart, theme, DB, VM2
│       ├── ctfd-aws-troubleshoot/   # runbook 4 pha
│       ├── ctfd-aws-security/       # hardening + secrets lifecycle
│       └── ctfd-aws-cost/           # chi phí + practice/competition toggle
├── commands/            # 13 slash commands (/aws-deploy, /aws-status, /aws-ssh...)
├── agents/              # 5 subagent: terraform-engineer, ansible-operator,
│                        #   incident-responder, security-hardener, devops-architect
├── hooks/               # 5 Python guards + README (stdin/stdout contract, test, bypass)
├── architecture/        # 8 docs kiến trúc AWS (README + 01..07, có mermaid diagrams)
└── scripts/             # check-env, setup-dev-env (ps1+sh), validate-all,
                         #   update-skills, test-hooks, new-skill
```

## Quickstart cho dev mới

```powershell
pwsh -File .claude/scripts/check-env.ps1        # 1. xem toolchain
pwsh -File .claude/scripts/setup-dev-env.ps1    # 2. cài pip tools + pre-commit
pwsh -File .claude/scripts/test-hooks.ps1       # 3. xác nhận guards chạy đúng
pwsh -File .claude/scripts/validate-all.ps1     # 4. validate IaC
# 5. mở Claude Code → hỏi /aws-status để kiểm tra AWS
```

## Nếu dùng Claude Code

- `CLAUDE.md` (root) tự load; skills tự discover theo frontmatter; `/aws-*` xuất hiện trong slash menu.
- Hooks trong `settings.json` tự kích hoạt (python cần có PATH).
- Subagents: gán qua `@terraform-engineer`, `@incident-responder`...

## Nếu dùng Cline / agent khác

- Đọc `CLAUDE.md` + `.claude/architecture/` làm system context.
- Tự kỷ luật theo `settings.json` (permissions) và `hooks/` như quy tắc an toàn.

## Sự thật đã xác minh tại thời điểm tạo

| Repo vendored | Commit HEAD |
|---|---|
| anthropics/skills | `34040c9c568585f6929bedeaad110ad08f079624` |
| obra/superpowers | `b36e0829c6d0140e93cfef2ca599b1b07d4a7797` |
| wshobson/agents | `4236bb91f8395b0435f1d8b8baf9e8e4c69a8620` |

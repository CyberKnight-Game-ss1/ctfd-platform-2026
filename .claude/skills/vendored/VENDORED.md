# Vendored DevOps Skills (clone upstream)

Các repo dưới đây được **clone về (shallow, depth=1)** và đã **gỡ `.git` nội bộ**
để vendoring thẳng vào repo này (không dùng git submodule → team chỉ cần `git pull` là có đủ).

| Repo upstream | Đích local | Commit HEAD lúc clone | Nội dung chính |
|---|---|---|---|
| https://github.com/anthropics/skills | `anthropic-skills/` | `34040c9c568585f6929bedeaad110ad08f079624` | Official Agent Skills: docx/pdf/pptx/xlsx, webapp-testing, mcp-builder, frontend-design... |
| https://github.com/obra/superpowers | `superpowers/` | `b36e0829c6d0140e93cfef2ca599b1b07d4a7797` | Framework kỹ năng + hooks: test-driven-development, systematic-debugging, verification-before-completion, brainstorming, writing/executing-plans, subagent-driven-development |
| https://github.com/wshobson/agents | `wshobson-agents/` | `4236bb91f8395b0435f1d8b8baf9e8e4c69a8620` | Marketplace 94 plugins / 202 agents / 183 skills / 105 commands — gồm các bộ DevOps: cloud-infrastructure, kubernetes-operations, devops-automation, incident-response, security... |

## Cách dùng

- **Tham chiếu trực tiếp**: đọc `SKILL.md`/agent files khi cần (agent có thể đọc on-demand
  theo progressive disclosure — chỉ đọc đúng skill liên quan, không đọc cả repo).
- **Cài như plugin Claude Code** (tùy chọn, giữ nguồn cập nhật upstream):
  ```
  /plugin marketplace add anthropics/skills
  /plugin marketplace add wshobson/agents
  ```
- **Chọn plugin DevOps đáng chú ý của wshobson-agents**: xem
  `wshobson-agents/docs/plugins.md` (catalog đầy đủ). Ví dụ: `kubernetes-operations`,
  `cloud-infrastructure`, `devops-automation`, `incident-response`, `backend-development`.

## Cập nhật

Chạy `.claude/scripts/update-skills.ps1` (hoặc slash command `/skills-update`) — script sẽ
re-clone ở commit mới nhất, cập nhật bảng SHA trong file này.

## Vì sao vendoring thay vì plugin-only?

1. Team làm việc offline/WAF có thể chặn marketplace; repo phải tự chứa đủ.
2. Đảm bảo mọi máy dev + mọi agent (Claude Code, Cline, Codex...) dùng chung một phiên bản skills.
3. Code review được: thay đổi skill đi qua PR như code thường.

# Skills

Skills = thư mục có `SKILL.md` (frontmatter `name` + `description`) dạy agent làm việc
lặp lại được theo cách chuẩn của dự án. Agent quét frontmatter (~100 tokens/skill),
chỉ load nội dung skill khi task liên quan (progressive disclosure).

## Cấu trúc

```
skills/
├── vendored/            # Skills DevOps clone từ upstream — xem vendored/VENDORED.md
│   ├── anthropic-skills/
│   ├── superpowers/
│   └── wshobson-agents/
└── ctfd-aws/            # Skills viết riêng cho repo này (nguồn sự thật = terraform/ + ansible/ thật)
    ├── ctfd-aws-architecture/SKILL.md
    ├── ctfd-aws-deploy/SKILL.md
    ├── ctfd-aws-terraform/SKILL.md
    ├── ctfd-aws-ansible/SKILL.md
    ├── ctfd-aws-operations/SKILL.md
    ├── ctfd-aws-troubleshoot/SKILL.md
    ├── ctfd-aws-security/SKILL.md
    └── ctfd-aws-cost/SKILL.md
```

## Quy ước viết skill mới

1. Tạo thư mục `skills/ctfd-aws/<skill-name>/SKILL.md` (kebab-case, prefix `ctfd-aws-`).
2. Frontmatter bắt buộc:
   ```yaml
   ---
   name: ctfd-aws-your-skill
   description: Viết rõ skill làm gì + KHI NÀO nên dùng (description là field quyết định việc agent có chọn skill hay không)
   ---
   ```
3. Nội dung < 5k tokens; tài nguyên phụ (script, template) đặt cạnh SKILL.md và tham chiếu tương đối.
4. Script scaffolding: chạy `.claude/scripts/new-skill.ps1 <name> "<description>"`.
5. Không đặt secret/URL nội bộ vào skill. Skill chỉ chứa kiến thức, không chứa giá trị nhạy cảm.

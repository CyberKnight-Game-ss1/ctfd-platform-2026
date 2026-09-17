---
description: Cập nhật các vendored DevOps skills trong .claude/skills/vendored/ từ upstream (re-clone + cập nhật VENDORED.md)
allowed-tools: Bash(git:*)
---

## Nhiệm vụ

1. Chạy script: `pwsh -File .claude/scripts/update-skills.ps1` (nếu PowerShell không có, thực hiện tay các bước dưới).
2. Quy trình tay (fallback): với từng repo trong `.claude/skills/vendored/VENDORED.md`:
   - `git clone --depth 1 <url> <tmp>` → ghi HEAD sha → xóa thư mục cũ → move tmp vào → xóa `.git` nội bộ.
   - Cập nhật bảng commit SHA trong `VENDORED.md`.
3. `git status` → tóm tắt thay đổi (file thêm/sửa/xoá) để user review trước khi commit.
4. Đề xuất: nếu upstream có breaking change lớn (đổi cấu trúc skill), ghi chú trong PR description.

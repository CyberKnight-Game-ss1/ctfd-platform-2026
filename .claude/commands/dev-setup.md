---
description: Thiết lập môi trường dev trên máy này (pip tools, pre-commit, kiểm tra toolchain) rồi chạy validate toàn repo
---

## Nhiệm vụ

1. Chạy `.claude/scripts/check-env.ps1` (PowerShell) để biết tool nào còn thiếu.
2. Chạy `.claude/scripts/setup-dev-env.ps1` — cài: ansible, ansible-lint, yamllint, pre-commit (pip), `pre-commit install` (hook git), optional tflint.
3. Chạy lại check-env để xác nhận.
4. `/aws-validate` để validate lần đầu.
5. Báo tổng kết: đã cài gì, còn thiếu gì (từ chối tự cài tool hệ thống ngoài pip như terraform/awscli — đưa link hướng dẫn).

Lưu ý môi trường Windows: dùng `python -m pip install --user` nếu pip system bị lock; không cài vào venv trừ khi user muốn.

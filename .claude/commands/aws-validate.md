---
description: Chạy toàn bộ validation cho IaC (terraform fmt/validate, yamllint, ansible-lint, py_compile hooks)
allowed-tools: Bash(terraform:*), Bash(yamllint:*), Bash(ansible-lint:*), Bash(python:*)
---

## Nhiệm vụ

Validate mọi thứ có thể validate offline (không đụng AWS):

1. `terraform -chdir=terraform/aws fmt -check -recursive` — nếu fail, tự chạy `fmt` để sửa rồi report diff.
2. `terraform -chdir=terraform/aws validate`
3. Nếu có `yamllint`: `yamllint ansible/ challenges/k8s/`
4. Nếu có `ansible-lint`: `ansible-lint ansible/`
5. `python -m py_compile .claude/hooks/*.py`
6. Nếu có `tflint` (optional): `tflint --chdir=terraform/aws`

Cài thiếu tool: đề nghị chạy `.claude/scripts/setup-dev-env.ps1`.

Báo cáo cuối dạng bảng: kiểm tra / kết quả / đã tự sửa gì.

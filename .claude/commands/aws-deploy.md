---
description: Deploy toàn bộ hạ tầng CTFd lên AWS theo quy trình chuẩn (gate check → terraform → inventory → ansible → checklist)
argument-hint: "[plan | apply]"
---

## Nhiệm vụ

Deploy/kiểm tra hạ tầng CTFd trên AWS. Mode: **$ARGUMENTS** (mặc định `plan`).

## Bước thực hiện

1. **Gate check** (làm trước, báo kết quả ngắn gọn):
   - `aws sts get-caller-identity --region ap-southeast-1` — account đúng không?
   - `terraform -chdir=terraform/aws validate`
   - `terraform.tfvars` tồn tại ở `terraform/aws/`? (chỉ `Test-Path`, KHÔNG đọc nội dung)
   - Ansible đã cài? `ansible-playbook --version`
2. **Skill load**: đọc `.claude/skills/ctfd-aws/ctfd-aws-deploy/SKILL.md` và làm đúng theo đó.
3. Nếu mode `plan`: chạy `terraform -chdir=terraform/aws plan -var-file=terraform.tfvars`, tóm tắt diff (thêm/sửa/xoá gì) cho user, **không apply**.
4. Nếu mode `apply`: trình bày tóm tắt plan trước, xin user xác nhận, rồi `terraform -chdir=terraform/aws apply -var-file=terraform.tfvars`. Sau đó:
   - `terraform -chdir=terraform/aws output` → hướng dẫn tạo `ansible/aws/inventory.ini` từ example
   - Nhắc chờ SSM agent (2-3 phút) → `aws ssm describe-instance-information`
   - Chạy ansible theo thứ tự (dry-run `-C --diff` trước mỗi play): `common/mtls_setup.yml` → `common/vm2_challenge.yml` → `aws/vm1_web.yml`
   - Nhắc user trỏ Cloudflare DNS A record → `vm1_web_public_ip`
5. **Hỏi user phương án DB** trước khi chạy `aws/vm1_web.yml` (A: PostgreSQL container như playbook hiện tại / B: dùng RDS từ SSM) — giải thích trade-off từ skill `ctfd-aws-architecture`.
6. Kết thúc bằng after-deploy checklist trong skill.

## Giới hạn

- KHÔNG chạy `terraform destroy` / terminate / delete (hook sẽ chặn).
- KHÔNG đọc `inventory.ini` đã điền IP thật, tfvars, tfstate.

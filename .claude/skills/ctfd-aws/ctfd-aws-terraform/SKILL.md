---
name: ctfd-aws-terraform
description: Quy ước viết và chạy Terraform cho cụm CTFd AWS — provider ~>5.0, biến bắt buộc, đối chiếu outputs, cách an toàn để plan/apply, các cờ flip khi lên production. Dùng khi sửa file .tf, thêm resource, hoặc chẩn đoán lỗi Terraform.
---

# Terraform — cụm AWS CTFd

## Thông số hiện tại

- Provider: `hashicorp/aws ~> 5.0` + `random ~> 3.5` (lockfile `.terraform.lock.hcl`).
- State: **local** (`terraform/aws/terraform.tfstate`) — KHÔNG commit (đã gitignore).
  ⚠️ Ưu tiên sau: migrate sang S3 backend + DynamoDB lock khi team đông hơn.
- Region mặc định trong code: `ap-southeast-1`.

## Biến (variables.tf)

| Biến | Mặc định | Ghi chú |
|---|---|---|
| `aws_region` | ap-southeast-1 | Không đổi |
| `vpc_cidr` | 10.0.0.0/16 | |
| `subnet_public_1_cidr` | 10.0.1.0/24 | VM1 + VM2 |
| `subnet_public_2_cidr` | 10.0.2.0/24 | Bắt buộc ≥2 AZ cho RDS subnet group |
| `cloudflare_ips` | 15 dải CF | Giữ đồng bộ với https://www.cloudflare.com/ips/ |
| `db_password` | **bắt buộc**, sensitive | Chỉ ghi trong `terraform.tfvars` local — KHÔNG bao giờ pass qua CLI history |
| `ctf_domain` | — | cyberknightgame.site |
| `is_practice_mode` | true | Spot VM2; **false** khi thi đấu thật. Spot dùng `spot_instance_type = "persistent"` + `instance_interruption_behavior = "stop"` — **AWS từ chối tổ hợp `one-time` + `stop`** (`InvalidParameterCombination: The request with type 'one-time' is not supported when instanceInterruptionBehavior is set to 'STOP'`). Persistent+stop giữ EBS khi bị thu hồi capacity |
| `vm1_instance_type` | t3.small | CTFd web — 2GB RAM, theo dõi OOM |
| `vm2_instance_type` | m7i-flex.large | 8GB cho Docker + K3s; thi đấu thật: On-Demand (`is_practice_mode=false`). **Bắt buộc là type free-tier-eligible vì account ở AWS Free plan** (`t3.large` bị từ chối) |
| `use_rds` | true | **false** = DB container trên VM1, không tạo RDS/SSM (đang dùng cho luyện tập 09/2026) |
| `db_instance_class` | db.t3.micro | db.t3.medium khi thi đấu |

## Quy tắc khi sửa code

1. Luôn `terraform fmt` (hook PostToolUse tự nhắc) và `terraform validate` trước khi plan.
2. Thêm resource mới → gắn tag `Project = "CyberKnight-CTF"` cho nhất quán.
3. Không hardcode secret trong `.tf` — chỉ tham chiếu `var.db_password` (sensitive) hoặc data SSM.
4. Sửa SG → nhớ mô hình: web = Cloudflare-only + FRP 7000 (VPC) + 10000-10100 (public); challenge = zero-inbound; db = 5432 từ sg_web.
5. Đổi instance type VM2 khi Spot → interruption behavior vẫn `stop` (không `terminate`).

## Chu trình lệnh an toàn

```bash
terraform -chdir=terraform/aws fmt
terraform -chdir=terraform/aws validate
terraform -chdir=terraform/aws plan -var-file=terraform.tfvars   # review kỹ diff
terraform -chdir=terraform/aws apply -var-file=terraform.tfvars  # chỉ sau khi user OK plan
```

- `destroy` bị **hook + permission deny chặn** — muốn xoá hạ tầng, user tự chạy.
- `apply -auto-approve` bị hook chặn → luôn cho user xem plan trước.

## Outputs quan trọng (outputs.tf)

`vm1_web_public_ip` · `vm2_challenge_public_ip` · `vm1_instance_id` · `vm2_instance_id` ·
`rds_endpoint` · `database_url_ssm_parameter` (/ctfd/database-url — **null khi `use_rds=false`**) · `s3_bucket_name`.

Lấy nhanh:
```bash
terraform -chdir=terraform/aws output vm1_web_public_ip
terraform -chdir=terraform/aws output -raw vm1_instance_id
```

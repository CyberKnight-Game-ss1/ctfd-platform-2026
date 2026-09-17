---
description: Hướng dẫn teardown hạ tầng CTFd AWS AN TOÀN (snapshot trước, sau đó destroy) — chỉ hướng dẫn, KHÔNG tự chạy
---

## Nhiệm vụ

⚠️ **Chỉ chuẩn bị kế hoạch teardown, tuyệt đối KHÔNG tự chạy destroy** (bị hook + permission chặn cố ý).

Mode: **$ARGUMENTS** — rỗng hoặc "plan".

1. Liệt kê chính xác thứ tự an toàn:
   a. Backup: RDS snapshot (`aws rds create-db-snapshot --db-instance-identifier ctf-postgres --db-snapshot-identifier ctf-postgres-final-<date>`), download PCAP từ S3.
   b. Disable EventBridge schedules (`aws scheduler update-schedule --state DISABLED`).
   c. User TỰ chạy: `terraform -chdir=terraform/aws destroy -var-file=terraform.tfvars` (review plan destroy kỹ: liệt kê số resource sẽ xoá).
   d. Verify: `aws ec2 describe-instances`, `aws s3 ls`, RDS list — còn sót gì không (SG/ENI mồ côi).
2. Cảnh báo rõ: skip_final_snapshot=true hiện tại nghĩa là **mất toàn bộ dữ liệu user/score/submission vĩnh viễn**. Đề nghị user flip `skip_final_snapshot=false` + `deletion_protection=true` trong `database.tf` trước khi destroy.
3. Nếu mục đích là "tiết kiệm chi phí": đề xuất thay thế rẻ hơn (stop VM1/VM2, RDS stop tạm, giữ IaC) thay vì destroy.

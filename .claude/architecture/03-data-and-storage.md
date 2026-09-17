# 03 — Data & Storage (RDS, SSM, S3)

> Nguồn sự thật: `terraform/aws/database.tf`, `terraform/aws/storage_and_automation.tf`, `ansible/aws/vm1_web.yml`

## RDS PostgreSQL 15 — `ctf-postgres`

| Thuộc tính | Giá trị | Ghi chú |
|---|---|---|
| Engine | postgres 15 | |
| Class | `db.t3.micro` (var `db_instance_class`) | → db.t3.medium khi giải thật |
| Storage | 20GB gp3, **encrypted** | |
| DB / user | `ctfd` / `ctfd` + `var.db_password` (sensitive) | |
| Network | `publicly_accessible = false`, SG `sg_db` | chỉ VM1 chạm được |
| Backup | 7 ngày, window 19:00-20:00 UTC (02:00-03:00 ICT) | |
| Maintenance | Mon 20:00-21:00 UTC | |
| **Production flips** | `skip_final_snapshot=true` → **false**; `deletion_protection=false` → **true** | bắt buộc trước giải thật |

## SSM Parameter Store

- `/ctfd/database-url` — SecureString (KMS mặc định), value:
  `postgresql://ctfd:<db_password>@<rds_endpoint>/ctfd`
- Đọc: `aws ssm get-parameter --name /ctfd/database-url --with-decryption --query "Parameter.Value" --output text --region ap-southeast-1`

## ⚠️ Hai phương án DB (điểm lệch pha Terraform ↔ Ansible)

Terraform provision RDS + SSM, nhưng `ansible/aws/vm1_web.yml` hiện viết compose
chạy **PostgreSQL container (`postgres:15-alpine`, data ở `/opt/ctfd/postgres`)**
với `DATABASE_URL=postgresql://ctfd:{{ db_password }}@db:5432/ctfd`.

| | **A — Container (hiện trạng playbook)** | **B — RDS (hiện trạng Terraform)** |
|---|---|---|
| Chi phí | +$0 (VM1 gánh) | ~$15/tháng |
| Backup | thủ công pg_dump | tự động PITR 7 ngày |
| Downtime khi reboot VM1 | có | không |
| Effort chuyển | 0 | sửa playbook: xoá service `db`, inject DATABASE_URL từ SSM vào env ctfd |
| Phù hợp | luyện tập ngân sách thấp | giải thật, dữ liệu quan trọng |

**Khuyến nghị agent:** hỏi user chọn phương án. Nếu A dài hạn → thêm flag
`use_rds` vào Terraform (`count = var.use_rds ? 1 : 0`) để không trả tiền RDS vô ích.

## S3 — `ctf-storage-<random_id 4 bytes>`

- `force_destroy = true` (luyện tập) → **false** khi giải thật.
- Block Public Access ×4 + SSE AES256.
- Lifecycle 1 rule: 7 ngày → STANDARD_IA, 30 ngày → GLACIER.
- Dùng cho: PCAP `/var/log/ctf-pcap/*.pcap` từ VM2, database dumps.

## EventBridge Scheduler (nằm cùng file storage)

| Schedule | Cron (UTC) | Giờ ICT | Target |
|---|---|---|---|
| `stop-vm2-nightly` | `0 17 * * ? *` | 00:00 | `stopInstances` VM2 |
| `start-vm2-morning` | `30 0 * * ? *` | 07:30 | `startInstances` VM2 |

- Timezone: `Asia/Ho_Chi_Minh`, flexible window OFF.
- Role `ctf-scheduler-role` → `ssm:StartAutomationExecution` + `ec2:Start/StopInstances` **giới hạn ARN VM2**.
- Cron EventBridge có 6 fields (thêm năm) — khác crontab thường, đừng "sửa cho gọn".

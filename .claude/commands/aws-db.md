---
description: Quản lý DATABASE_URL / RDS / database CTFd (xem endpoint, hướng dẫn backup/restore, migration)
argument-hint: "[url | info | backup | restore | migrate]"
---

## Nhiệm vụ

Mode: **$ARGUMENTS** (mặc định `info`).

- `info`: `aws rds describe-db-instances --db-instance-identifier ctf-postgres --region ap-southeast-1` — status, class, endpoint, public, encrypted, backup retention. Nhắc user: cụm hiện chạy PostgreSQL container trên VM1 theo playbook — xác nhận mode DB đang dùng trước khi kết luận.
- `url`: in ra lệnh để user TỰ chạy (không tự chạy để tránh password vào transcript):
  `aws ssm get-parameter --name /ctfd/database-url --with-decryption --query "Parameter.Value" --output text --region ap-southeast-1`
- `backup`: hướng dẫn snapshot RDS (`aws rds create-db-snapshot`) hoặc `pg_dump` từ VM1 qua SSM; với mode container: `docker exec db pg_dump -U ctfd ctfd > backup.sql`.
- `restore`: quy trình point-in-time restore RDS / pg_restore, kèm cảnh báo downtime.
- `migrate`: CTFd dùng Flask-Migrate/alembic — hướng dẫn chạy `docker exec ctfd python manage.py db upgrade` trên VM1, chỉ sau backup.

CẢNH BÁO: mọi lệnh DROP/TRUNCATE/delete-db-instance bị hook chặn — nếu user thật sự muốn xoá, giải thích rủi ro + yêu cầu tự chạy.

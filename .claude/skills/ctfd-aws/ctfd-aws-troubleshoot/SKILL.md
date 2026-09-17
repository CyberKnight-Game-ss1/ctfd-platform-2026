---
name: ctfd-aws-troubleshoot
description: Runbook chẩn đoán sự cố cụm CTFd AWS theo quy trình 4 pha (triệu chứng → tầng nào → kiểm tra → khắc phục) — site không tải, 5xx, CTFd crash, Whale không tạo instance, DB connection fail. Dùng khi có sự cố hoặc user báo lỗi hệ thống.
---

# Troubleshooting Runbook — 4 pha

## Pha 1 — Xác định tầng lỗi

```
Player → Cloudflare → SG → Nginx → CTFd(:8000) → Redis / DB / FRP→VM2(Docker)
```
Hỏi/sép hẹp: mọi user hay 1 user? HTTP mấy mã? Domain hay IP? Lúc nào bắt đầu?

## Pha 2 — Kiểm tra từng tầng

| Tầng | Kiểm tra |
|---|---|
| Cloudflare | Proxy cam? SSL mode Full (strict)? WAF chặn? Rate limit? |
| EC2 | `aws ec2 describe-instance-status --instance-ids $VM1_ID --region ap-southeast-1` — 2/2 checks passed? |
| Nginx | `aws logs tail /ctfd/nginx/error --follow` |
| CTFd | SSM vào VM1 → `docker compose ps`, `docker compose logs --tail 100 ctfd` |
| Redis | `docker exec ctfd_cache_1 redis-cli ping` |
| DB (container) | `docker compose ps db`, `docker compose logs --tail 50 db` |
| DB (RDS) | `aws rds describe-db-instances --db-instance-identifier ctf-postgres --region ap-southeast-1` — status available? `DatabaseConnections`? |
| FRP/Whale | VM2: `docker ps | grep proxy`; VM1: log ctfd có `whale`/`frp` error? port 10000-10100 busy? |
| K3s (VM2) | `k3s kubectl get nodes`, `k3s kubectl get pods -A` |

## Pha 3 — Các sự cố phổ biến & cách sửa

**Site trả 502/504**
→ CTFd container chết: `docker compose logs ctfd`; thường do DB chờ quá lâu lúc boot — restart: `sudo docker compose restart ctfd`.

**CTFd loop login / session mất liên tục**
→ `SECRET_KEY` đổi giữa các lần build → logout toàn bộ user. Giữ SECRET_KEY cố định qua extra-vars, không regenerate.

**Template sửa không ăn**
→ Redis cache: `redis-cli FLUSHALL` trong container cache (bắt buộc).

**Whale không tạo instance**
1. `docker ps` trên VM2 thấy `docker-proxy` đang chạy?
2. frpc/frps connected? (log frps VM1)
3. Whale config trong admin: Docker API URL đúng tunnel chưa, subnet pool chưa overlapping?
4. K3s network policy có deny-all egress của pod challenge chưa đúng namespace?

**DB connection refused (RDS)**
→ SG sg_db chỉ nhận 5432 từ sg_web; RDS status; DATABASE_URL trong SSM đúng endpoint chưa.

**Disk full VM2 (challenges nhiều image)**
→ `docker system df`; prune an toàn (có hook chặn `prune -a` — dùng có chọn lọc từng image dư); cân nhắc EBS volume up.

**SSM session fail**
→ Instance profile `ctf-vm-profile` gắn chưa; SSM agent online (`aws ssm describe-instance-information`); SG egress 443 mở.

## Pha 4 — Sau sự cố

1. Ghi lại timeline + root cause vào `docs/aws/02-aws-troubleshooting.md` (PR review).
2. Nếu dữ liệu mất: restore từ RDS snapshot / S3 backup.
3. Cân nhắc thêm alarm CloudWatch cho metric vừa phát hiện.

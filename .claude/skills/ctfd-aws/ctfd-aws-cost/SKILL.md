---
name: ctfd-aws-cost
description: Mô hình chi phí cụm CTFd AWS (~$45-60/tháng) và các đòn bẩy tối ưu — Spot VM2, EventBridge tắt ban đêm, S3 lifecycle, Reserved Instance. Dùng khi user hỏi chi phí, tối ưu hóa, hoặc chuẩn bị ngân sách giải đấu.
---

# Cost Model & Optimization

## Chi phí hiện tại (ap-southeast-1, luyện tập)

| Resource | Spec | $/tháng |
|---|---|---|
| VM1 `ctf-vm1-web` | t3.medium On-Demand | ~30 |
| VM2 `ctf-vm2-challenge` | t3.small/large **Spot** (~70% off) | ~6-12 |
| RDS `ctf-postgres` | db.t3.micro, 20GB gp3 | ~15 |
| S3 | <10GB + lifecycle IA→Glacier | <1 |
| EventBridge Scheduler | 2 schedules | ~0.1 |
| SSM Parameter Store | SecureString | 0 |
| CloudWatch Logs | <5GB | ~2 |
| **Tổng luyện tập** | | **~$50-60** |

## Đòn bẩy tối ưu

1. **EventBridge tắt VM2 ban đêm** (đã cấu hình: 00:00→07:30 ICT) — tiết kiệm ~31% giờ VM2. Giữ nguyên.
2. **Spot VM2** (`is_practice_mode=true`) — chỉ tắt khi thi đấu. Interruption = `stop`, không mất EBS.
3. **S3 lifecycle** 7 ngày → IA (-45%), 30 ngày → Glacier (-80%) — đã cấu hình.
4. **Reserved/Savings Plan cho VM1** 1 năm — ~$18/tháng nếu cụm chạy dài hạn.
5. **Nghi vấn lớn: RDS có đang bị trả tiền mà không dùng?** Playbook hiện chạy PostgreSQL container trên VM1 (xem skill architecture). Nếu chọn phương án A: comment resource `aws_db_instance` + `aws_ssm_parameter` hoặc tách qua `count = var.use_rds ? 1 : 0` → tiết kiệm ~$15/tháng. Đề xuất refactor này cho user.
6. **CloudWatch log retention** — set 90 ngày cho cả 3 group (mặc định là never-expire = tốn tiền vô hạn; 90 ngày đủ cửa sổ tra gian lận): `for g in /ctfd/nginx/access /ctfd/nginx/error /ctfd/application; do aws logs put-retention-policy --log-group-name "$g" --retention-in-days 90 --region ap-southeast-1; done`.

## Khi thi đấu thật (1 tuần giải)

- VM1: t3.medium → giữ, hoặc `c6i.large` nếu CPU-bound lúc nhiều player.
- VM2: `is_practice_mode=false` + tăng `vm2_instance_type` (m7i-flex.large/xlarge tùy số challenge động — phải là type free-tier-eligible khi account còn ở Free plan).
- RDS: db.t3.micro → db.t3.medium, bật deletion protection.
- Dự kiến thêm ~$40-80 cho tuần giải (On-Demand + traffic Cloudflare free tier đủ).

## Kiểm tra chi phí thực tế

```bash
aws ce get-cost-and-usage \
  --time-period Start=2026-01-01,End=2026-02-01 \
  --granularity MONTHLY --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE --region ap-southeast-1
```
(Cần quyền `ce:GetCostAndUsage` trên account; command đã allow trong permissions.)

# 07 — Cost Model

> Nguồn sự thật: `terraform/aws/variables.tf` (instance types, spot), `storage_and_automation.tf` (lifecycle, scheduler), `docs/aws/01-aws-infrastructure.md`

## Chi phí luyện tập (ap-southeast-1)

| Resource | Spec | $/tháng |
|---|---|---|
| VM1 ctf-vm1-web | t3.small On-Demand 24/7 | ~15 |
| Public IPv4 | VM1 EIP (VM2 dùng IP động, nhả khi stop đêm) | ~3.5 |
| VM2 ctf-vm2-challenge | m7i-flex.large Spot + tắt ban đêm (00:00→07:30 ICT) | ~25-29 |
| RDS ctf-postgres | **đã tắt (`use_rds=false` — DB container trên VM1)** | 0 |
| S3 | <10GB, lifecycle IA→Glacier | <1 |
| EventBridge | 2 schedules | ~0.1 |
| SSM Parameter | SecureString tier free | 0 |
| CloudWatch Logs | <5GB | ~2 |
| EBS | 80GB gp3 (VM1 30 + VM2 50) | ~6 |
| **Tổng** | | **~53-58** |

> Cấu hình 09/2026: VM1 t3.small + EIP · VM2 **m7i-flex.large Spot** · RDS tắt (`use_rds=false`) → ~$53-58/tháng.
> Lý do đổi VM2 từ `t3.large` → `m7i-flex.large`: account ở **AWS Free plan**, chỉ được launch instance type
> free-tier-eligible. Allowlist của ap-southeast-1: `t3.micro`, `t3.small`, `t4g.micro`, `t4g.small`,
> `c7i-flex.large` (4GB), **`m7i-flex.large` (8GB)** — chỉ `m7i-flex.large` đạt 8GB + x86_64.
> Spot price AZ-a (nơi VM2 chạy) ~$0.058/giờ. Bật lại RDS khi giải thật thì thêm ~$15.

## Đòn bẩy tiết kiệm theo mức độ can thiệp

1. **Đã bật sẵn**: Spot VM2 · schedule tắt đêm · S3 lifecycle · SSM free tier.
2. **Đã áp dụng 09/2026**: `use_rds=false` tắt RDS (DB container trên VM1, ~-$15) · VM1 xuống t3.small (~-$15) · VM2 lên **m7i-flex.large Spot** (~+$9, do account ở Free plan chỉ cho type free-tier-eligible) · EIP cho VM1 (~+$3.5, trung tính vì IP động cũng bị tính phí — đổi lại IP không đổi khi restart). Còn lại cần làm: log retention 30 ngày (CloudWatch).
3. **Cam kết dài hạn**: Reserved Instance / Savings Plan cho VM1 (→ ~$18/tháng, tiết kiệm 40%).
4. **Cấu trúc lại (tốn effort)**: chỉ chạy cụm khi có giải (schedule toàn cụm), state S3 backend vẫn free tier.

## Chế độ thi đấu thật (flip checklist)

| Var/attr | Luyện tập | Thi đấu thật |
|---|---|---|
| `is_practice_mode` | true (Spot) | **false** (On-Demand, không interrupt) |
| `vm2_instance_type` | m7i-flex.large Spot | m7i-flex.large On-Demand (hoặc c7i-flex.large nếu 4GB đủ — vẫn phải free-tier-eligible) |
| `use_rds` | false (DB container trên VM1) | **true** (provision RDS) |
| `db_instance_class` | db.t3.micro | db.t3.medium |
| `deletion_protection` (RDS) | false | **true** |
| `skip_final_snapshot` (RDS) | true | **false** |
| S3 `force_destroy` | true | **false** |
| FRP token / SECRET_KEY | default repo | **rotate** |

Chi phí tuần giải ước tính: +$40-80 (On-Demand VM2 + RDS medium), Cloudflare free tier đủ.

## Kiểm tra thực tế

```bash
aws ce get-cost-and-usage --time-period Start=<YYYY-MM-01>,End=<YYYY-MM-01> \
  --granularity MONTHLY --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE --region ap-southeast-1
```
Slash command: `/aws-cost` (tự chạy + so với bảng này).

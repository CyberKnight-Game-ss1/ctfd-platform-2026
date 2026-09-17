# 05 — Observability (CloudWatch, PCAP, Schedules)

> Nguồn sự thật: `ansible/aws/vm1_web.yml` (CloudWatch Agent), `ansible/common/vm2_challenge.yml` (tcpdump), `storage_and_automation.tf` (EventBridge)

## Log pipeline

```
VM1: Nginx access/error + CTFd app log → CloudWatch Agent → CloudWatch Logs
     /ctfd/nginx/access · /ctfd/nginx/error · /ctfd/application
VM2: PCAP → /var/log/ctf-pcap/%Y%m%d-%H%M%S.pcap → S3 (thủ công/lịch)
```

## Lệnh xem log

```bash
aws logs tail /ctfd/nginx/access --follow --region ap-southeast-1
aws logs tail /ctfd/nginx/error  --follow --region ap-southeast-1
aws logs tail /ctfd/application  --follow --region ap-southeast-1

# Filter lỗi 24h qua
aws logs filter-log-events --log-group-name /ctfd/application \
  --start-time $(date -d '24 hours ago' +%s000) \
  --filter-pattern "?ERROR ?Traceback" --region ap-southeast-1
```

⚠️ Log group **mặc định không expire** — phải set retention, nếu không CloudWatch giữ log vĩnh viễn và tính tiền lưu trữ mãi:
```bash
for g in /ctfd/nginx/access /ctfd/nginx/error /ctfd/application; do
  aws logs put-retention-policy --log-group-name "$g" --retention-in-days 90 --region ap-southeast-1
done
```

## Log format forensics (nginx — thêm 09/2026 phục vụ điều tra gian lận)

`log_format ctfd_forensics` trong `vm1_web.yml`:
- `$remote_addr` = **IP player thật** nhờ `ngx_http_realip`: `set_real_ip_from` = 15 dải
  Cloudflare (khớp `cloudflare_ips` trong Terraform) + `real_ip_header CF-Connecting-IP`.
  Không có realip thì log chỉ chứa IP edge Cloudflare — vô dụng khi truy vết.
- Kèm `cf_ray` (đối chiếu 1-1 với Cloudflare analytics), `user_agent`, `request_time`.
- CTFd chạy `REVERSE_PROXY=True` + realip → bảng `submissions` trong DB CTFd lưu **IP thật**.

Query Logs Insights truy vết một trường hợp nghi vấn:
```
fields @timestamp, @message
| filter @message like /203.0.113.42/   # IP nghi vấn
| sort @timestamp desc
```

⚠️ Retention: sau deploy set **90 ngày** (tra gian lận cần cửa sổ dài hơn 30):
```bash
for g in /ctfd/nginx/access /ctfd/nginx/error /ctfd/application; do
  aws logs put-retention-policy --log-group-name "$g" --retention-in-days 90 --region ap-southeast-1
done
```

## PCAP capture (VM2)

systemd `ctf-tcpdump`:
```bash
tcpdump -i docker0 -w '/var/log/ctf-pcap/%Y%m%d-%H%M%S.pcap' -G 1800 -W 48 -Z root
```
- `-G 1800` rotate mỗi 30 phút; `-W 48` giữ tối đa 48 file (24 giờ).
- Interface `docker0` = traffic Docker network (challenge ↔ player).
- Upload lên S3: `aws s3 cp /var/log/ctf-pcap/ s3://<bucket>/pcap/ --recursive --include "*.pcap"`.

## Alarm khuyến nghị (chưa có — cần thêm khi lên giải thật)

| Metric | Điều kiện | Action |
|---|---|---|
| Nginx 5xx rate | > 5%/5min | SNS → team |
| RDS `DatabaseConnections` | > 40 | kiểm tra connection leak |
| EC2 VM1 CPU | > 80%/15min | scale type lên |
| SSM ping VM2 | mất > 10min khi schedule đang ON | Spot interrupted? |

## Kế hoạch bật/tắt VM2

- `stop-vm2-nightly` 00:00 ICT · `start-vm2-morning` 07:30 ICT (EventBridge, TZ Asia/Ho_Chi_Minh).
- Lịch là "mặc định": thao tác thủ công có thể bị lịch ghi đè — nếu cần giữ VM2 chạy ban đêm (giải cuối tuần), `aws scheduler update-schedule --state DISABLED`.

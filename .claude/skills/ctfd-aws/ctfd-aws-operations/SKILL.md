---
name: ctfd-aws-operations
description: Vận hành hằng ngày cụm CTFd trên AWS — SSH qua SSM, xem logs CloudWatch, restart CTFd, flush Redis, deploy theme, quản lý DATABASE_URL, bật/tắt VM2 theo lịch. Dùng cho mọi tác vụ day-2 operation.
---

# Day-2 Operations

## SSH / SSM (không port 22)

```bash
VM1_ID=$(terraform -chdir=terraform/aws output -raw vm1_instance_id)
VM2_ID=$(terraform -chdir=terraform/aws output -raw vm2_instance_id)
aws ssm start-session --target $VM1_ID --region ap-southeast-1
aws ssm start-session --target $VM2_ID --region ap-southeast-1
```
Cần Session Manager plugin. SCP: thêm `-o ProxyCommand="aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p"`.

## Logs (CloudWatch)

```bash
aws logs tail /ctfd/nginx/access --follow --region ap-southeast-1
aws logs tail /ctfd/nginx/error  --follow --region ap-southeast-1
aws logs tail /ctfd/application  --follow --region ap-southeast-1
```

## Trên VM1 (qua SSM session)

```bash
cd /opt/ctfd
sudo docker compose ps                    # trạng thái stack
sudo docker compose logs -f ctfd          # log app
sudo docker compose restart ctfd          # restart CTFd (DATABASE_URL đã trong env/compose)
sudo docker exec ctfd_cache_1 redis-cli FLUSHALL   # flush template cache
sudo docker exec ctfd_cache_1 redis-cli --scan | head    # liệt kê key cache
```

## DATABASE_URL

Nằm trong SSM SecureString (RDS mode) hoặc compose (container mode):
```bash
aws ssm get-parameter --name /ctfd/database-url --with-decryption \
  --query "Parameter.Value" --output text --region ap-southeast-1
```
⚠️ Giá trị chứa password — chỉ dùng trên máy/VM tin cậy, không dán vào ticket/chat.

## VM2 bật/tắt theo lịch (EventBridge, Asia/Ho_Chi_Minh)

- `stop-vm2-nightly` cron `0 17 * * ? *` (UTC) = 00:00 ICT
- `start-vm2-morning` cron `30 0 * * ? *` (UTC) = 07:30 ICT

Thủ công:
```bash
aws ec2 stop-instances --instance-ids $VM2_ID --region ap-southeast-1
aws ec2 start-instances --instance-ids $VM2_ID --region ap-southeast-1
```

## Upload PCAP lên S3 (trên VM2)

```bash
aws s3 cp /var/log/ctf-pcap/ s3://$(terraform -chdir=terraform/aws output -raw s3_bucket_name)/pcap/ --recursive --exclude "*" --include "*.pcap"
```
Lifecycle bucket đã tự chuyển STANDARD_IA sau 7 ngày, GLACIER sau 30 ngày.

## Checklist trước giờ thi (chuyển practice → competition)

1. `is_practice_mode=false` + `terraform apply` (VM2 On-Demand, đúng type `m7i-flex.large` — account Free plan chỉ cho type free-tier-eligible).
2. RDS: `db_instance_class=db.t3.medium`, `deletion_protection=true`, `skip_final_snapshot=false`.
3. S3: `force_destroy=false`.
4. Số lượng worker CTFd tăng nếu cần (`WORKERS` env trong compose).
5. Snapshot RDS + download PCAP ngày trước đó.

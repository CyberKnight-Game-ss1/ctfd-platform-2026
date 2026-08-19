# Hướng dẫn Triển khai trên Amazon Web Services (AWS)

## Tổng quan kiến trúc

```
[Người dùng] → HTTPS → [Cloudflare CDN/WAF]
                              ↓
                    [AWS VPC - ap-southeast-1]
                    [Security Group: sg_web]
                              ↓
                    [VM1: ctf-vm1-web - EC2 t3.medium]
                    ┌──────────────────────────────┐
                    │  Nginx (reverse proxy :80)   │
                    │  CTFd App         (:8000)    │
                    │  Redis            (:6379)    │
                    └──────────────┬───────────────┘
                                   │ sg_db (port 5432)
                    ┌──────────────┴───────────────┐
                    │ RDS PostgreSQL 15 (Private)  │
                    └──────────────────────────────┘
                                   │ sg_challenge (mTLS :2376)
                    [VM2: ctf-vm2-challenge - EC2 t3.large]
                    ┌──────────────────────────────┐
                    │  Docker Socket Proxy (mTLS)  │
                    │  K3s (Kubernetes)            │
                    │  tcpdump PCAP rotation       │
                    └──────────────────────────────┘
```

## Yêu cầu chuẩn bị

- **AWS Account** có quyền tạo VPC, EC2, RDS, S3, IAM, SSM, EventBridge.
- **AWS CLI** >= v2 đã cài và đã config (`aws configure` hoặc dùng IAM Identity Center).
- **Terraform** >= 1.5 đã cài.
- **Ansible** >= 2.12 đã cài.
- **SSH keypair** (`~/.ssh/id_rsa` và `~/.ssh/id_rsa.pub`).

## Bước 1 – Cấu hình AWS CLI

```bash
aws configure
# AWS Access Key ID: <YOUR_ACCESS_KEY>
# AWS Secret Access Key: <YOUR_SECRET_KEY>
# Default region name: ap-southeast-1
# Default output format: json
```

## Bước 2 – Provision hạ tầng bằng Terraform

```bash
cd terraform/aws

# Khởi tạo Terraform (tải AWS provider)
terraform init

# Xem trước những gì sẽ được tạo
terraform plan \
  -var="db_password=<DB_PASSWORD>" \
  -var="ctf_domain=cyberknightgame.site"

# Áp dụng (tạo hạ tầng, mất khoảng 10-15 phút vì RDS cần thời gian khởi tạo)
terraform apply \
  -var="db_password=<DB_PASSWORD>" \
  -var="ctf_domain=cyberknightgame.site"
```

Sau khi apply xong, lưu lại output:

```bash
terraform output
# vm1_web_public_ip          = "x.x.x.x"
# vm2_challenge_public_ip    = "y.y.y.y"
# vm1_instance_id            = "i-0xxxxxxxxxxxxxxxxx"
# vm2_instance_id            = "i-0yyyyyyyyyyyyyyyyy"
# rds_endpoint               = "ctf-postgres.xxxxxxxxx.ap-southeast-1.rds.amazonaws.com:5432"
# database_url_ssm_parameter = "/ctfd/database-url"
# s3_bucket_name             = "ctf-storage-xxxxxxxx"
```

## Bước 3 – Cấu hình Ansible inventory

```bash
cd ansible/aws
cp inventory.ini.example inventory.ini
# Điền IP VM1 và VM2 từ terraform output vào inventory.ini
```

## Bước 4 – Chờ SSM Agent sẵn sàng

Sau khi EC2 khởi động, chờ 2-3 phút để SSM Agent kết nối:

```bash
# Kiểm tra VM1 đã kết nối SSM chưa
aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=$(terraform output -raw vm1_instance_id)"
```

## Bước 5 – Phân phối chứng chỉ mTLS

```bash
cd ansible
ansible-playbook -i aws/inventory.ini common/mtls_setup.yml
```

## Bước 6 – Cấu hình Challenge Server (VM2)

```bash
ansible-playbook -i aws/inventory.ini common/vm2_challenge.yml
```

## Bước 7 – Cấu hình Web Server (VM1) và deploy CTFd

```bash
ansible-playbook -i aws/inventory.ini aws/vm1_web.yml
```

## Bước 8 – Trỏ DNS Cloudflare

Trỏ bản ghi A của domain về IP của VM1. Bật **Cloudflare Proxy** (màu cam).

## Quản lý & Vận hành

### SSH vào EC2 qua SSM Session Manager (không cần mở port 22)

```bash
# Cài Session Manager plugin nếu chưa có
# Xem: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

# SSH vào VM1
aws ssm start-session --target $(terraform output -raw vm1_instance_id) \
  --region ap-southeast-1

# SSH vào VM2
aws ssm start-session --target $(terraform output -raw vm2_instance_id) \
  --region ap-southeast-1
```

### Copy file lên VM1 qua SSH (dùng SSM proxy)

```bash
# Lấy instance ID
VM1_ID=$(cd terraform/aws && terraform output -raw vm1_instance_id)

# SSH với ProxyCommand SSM
ssh -o ProxyCommand="aws ssm start-session \
  --target %h \
  --document-name AWS-StartSSHSession \
  --parameters portNumber=%p \
  --region ap-southeast-1" \
  ubuntu@$VM1_ID

# Hoặc dùng SCP để copy file
scp -o ProxyCommand="aws ssm start-session \
  --target %h \
  --document-name AWS-StartSSHSession \
  --parameters portNumber=%p \
  --region ap-southeast-1" \
  themes/ctfd-theme-neubrutalism/templates/login.html \
  ubuntu@$VM1_ID:/home/ubuntu/
```

### Cập nhật template và flush Redis

```bash
aws ssm send-command \
  --instance-ids $VM1_ID \
  --document-name "AWS-RunShellScript" \
  --parameters commands=[
    "sudo cp /home/ubuntu/login.html /opt/ctfd/themes/ctfd-theme-neubrutalism/templates/login.html",
    "sudo docker exec ctfd_cache_1 redis-cli FLUSHALL"
  ]
```

### Bắt đầu/Dừng VM2 thủ công

```bash
VM2_ID=$(cd terraform/aws && terraform output -raw vm2_instance_id)

# Dừng VM2
aws ec2 stop-instances --instance-ids $VM2_ID --region ap-southeast-1

# Khởi động VM2
aws ec2 start-instances --instance-ids $VM2_ID --region ap-southeast-1
```

### Xem logs CloudWatch

```bash
# Xem Nginx access log gần nhất
aws logs tail /ctfd/nginx/access --follow --region ap-southeast-1

# Xem Nginx error log
aws logs tail /ctfd/nginx/error --follow --region ap-southeast-1

# Xem application log
aws logs tail /ctfd/application --follow --region ap-southeast-1
```

### Lấy DATABASE_URL từ SSM

```bash
aws ssm get-parameter \
  --name "/ctfd/database-url" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text \
  --region ap-southeast-1
```

## Chi phí ước tính (AWS - ap-southeast-1 Singapore)

| Resource | Spec | Chi phí/tháng |
|---|---|---|
| VM1 (ctf-vm1-web) | EC2 t3.medium On-Demand | ~$30 |
| VM2 (ctf-vm2-challenge) | EC2 t3.large Spot (~70% off) | ~$12 |
| RDS PostgreSQL | db.t3.micro, 20GB gp3 | ~$15 |
| S3 Bucket | < 10 GB | < $1 |
| EventBridge Scheduler | 2 schedules | ~$0.10 |
| SSM Parameter Store | SecureString (miễn phí 10k API calls/tháng) | $0 |
| CloudWatch Logs | < 5 GB | ~$2 |
| **Tổng** | | **~$60/tháng** |

> **Mẹo tiết kiệm**: Dùng EC2 Reserved Instance 1 năm cho VM1 có thể giảm chi phí xuống còn ~$18/tháng.

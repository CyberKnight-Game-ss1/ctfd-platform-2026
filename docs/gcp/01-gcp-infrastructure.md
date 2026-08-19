# Hướng dẫn Triển khai trên Google Cloud Platform (GCP)

## Tổng quan kiến trúc

```
[Người dùng] → HTTPS → [Cloudflare CDN/WAF]
                              ↓
                       [GCP VPC Network]
                              ↓
                    [VM1: ctf-vm1-web - e2-medium]
                    ┌──────────────────────────────┐
                    │  Nginx (reverse proxy :80)   │
                    │  CTFd App         (:8000)    │
                    │  Redis            (:6379)    │
                    └──────────────┬───────────────┘
                                   │ Private IP
                    ┌──────────────┴───────────────┐
                    │ Cloud SQL PostgreSQL (Private)│
                    └──────────────────────────────┘
                                   │ mTLS :2376
                    [VM2: ctf-vm2-challenge - e2-standard-2]
                    ┌──────────────────────────────┐
                    │  Docker Socket Proxy (mTLS)  │
                    │  K3s (Kubernetes)            │
                    │  tcpdump PCAP rotation       │
                    └──────────────────────────────┘
```

## Yêu cầu chuẩn bị

- **GCP Project** đã tạo, billing đã bật.
- **gcloud CLI** đã cài và đã đăng nhập (`gcloud auth login`).
- **Terraform** >= 1.5 đã cài.
- **Ansible** >= 2.12 đã cài.
- **SSH keypair** (`~/.ssh/id_rsa` và `~/.ssh/id_rsa.pub`).

## Bước 1 – Kích hoạt các GCP APIs cần thiết

```bash
gcloud services enable compute.googleapis.com \
  sqladmin.googleapis.com \
  servicenetworking.googleapis.com \
  secretmanager.googleapis.com \
  cloudscheduler.googleapis.com \
  storage.googleapis.com
```

## Bước 2 – Provision hạ tầng bằng Terraform

```bash
cd terraform/gcp

# Khởi tạo Terraform
terraform init

# Xem trước những gì sẽ được tạo
terraform plan -var="project_id=<GCP_PROJECT_ID>" \
               -var="db_password=<DB_PASSWORD>" \
               -var="ctf_domain=cyberknightgame.site"

# Áp dụng (tạo hạ tầng)
terraform apply -var="project_id=<GCP_PROJECT_ID>" \
                -var="db_password=<DB_PASSWORD>" \
                -var="ctf_domain=cyberknightgame.site"
```

Sau khi apply xong, lưu lại output:

```bash
terraform output
# vm1_web_public_ip       = "x.x.x.x"
# vm2_challenge_public_ip = "y.y.y.y"
# cloud_sql_private_ip    = "10.x.x.x"
# database_url_secret_name = "ctfd-db-connection"
# gcs_bucket_name         = "ctf-storage-xxxxxxxx"
```

## Bước 3 – Cấu hình Ansible inventory

```bash
cd ansible/gcp
cp inventory.ini.example inventory.ini
# Điền IP VM1 và VM2 vào inventory.ini
```

## Bước 4 – Phân phối chứng chỉ mTLS

> **Chú ý:** Cần generate mTLS certs trước. Xem `docs/common/03-challenges-k8s.md` để biết cách tạo.

```bash
cd ansible
ansible-playbook -i gcp/inventory.ini common/mtls_setup.yml
```

## Bước 5 – Cấu hình Challenge Server (VM2)

```bash
ansible-playbook -i gcp/inventory.ini common/vm2_challenge.yml
```

## Bước 6 – Cấu hình Web Server (VM1) và deploy CTFd

```bash
ansible-playbook -i gcp/inventory.ini gcp/vm1_web.yml
```

## Bước 7 – Trỏ DNS Cloudflare

Trỏ bản ghi A của domain (ví dụ: `cyberknightgame.site`) về IP của VM1.
Bật **Cloudflare Proxy** (màu cam) để hưởng DDoS protection và WAF.

## Quản lý & Vận hành

### SSH vào VM qua IAP (không cần mở port 22 ra internet)

```bash
# SSH vào VM1
gcloud compute ssh ubuntu@ctf-vm1-web --tunnel-through-iap

# SSH vào VM2
gcloud compute ssh ubuntu@ctf-vm2-challenge --tunnel-through-iap
```

### Copy file lên VM qua IAP

```bash
# Copy template mới lên VM1
gcloud compute scp "themes/ctfd-theme-neubrutalism/templates/login.html" \
  ubuntu@ctf-vm1-web:/home/ubuntu/ --tunnel-through-iap

# Copy file vào volume Docker và flush Redis cache
gcloud compute ssh ubuntu@ctf-vm1-web --tunnel-through-iap --command="
  sudo cp /home/ubuntu/login.html /opt/ctfd/themes/ctfd-theme-neubrutalism/templates/login.html &&
  sudo docker exec ctfd_cache_1 redis-cli FLUSHALL
"
```

### Bắt đầu/Dừng VM2 thủ công

```bash
# Dừng VM2
gcloud compute instances stop ctf-vm2-challenge --zone=asia-southeast1-a

# Khởi động VM2
gcloud compute instances start ctf-vm2-challenge --zone=asia-southeast1-a
```

### Xem logs Docker

```bash
# Xem logs CTFd
sudo docker logs -f ctfd_ctfd_1

# Xem logs Redis
sudo docker logs -f ctfd_cache_1
```

## Chi phí ước tính (GCP - Asia Southeast 1)

| Resource | Spec | Chi phí/tháng |
|---|---|---|
| VM1 (ctf-vm1-web) | e2-medium (On-Demand) | ~$13 |
| VM2 (ctf-vm2-challenge) | e2-standard-2 (Spot) | ~$7 |
| Cloud SQL | db-f1-micro | ~$7 |
| GCS Bucket | < 10 GB | < $1 |
| **Tổng** | | **~$28/tháng** |

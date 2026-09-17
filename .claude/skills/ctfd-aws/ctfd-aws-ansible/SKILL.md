---
name: ctfd-aws-ansible
description: Quy ước chạy Ansible cho cụm CTFd — thứ tự playbook mtls → vm2 → vm1, inventory qua SSM/SSH ProxyCommand, idempotency, dry-run -C trước, và các var quan trọng trong vm1_web.yml. Dùng khi chạy/sửa playbook hoặc troubleshoot cấu hình máy ảo.
---

# Ansible — cấu hình VM1/VM2

## Inventory

- `ansible/aws/inventory.ini` là file sinh tự động (`pwsh -File .claude/scripts/gen-inventory.ps1`) → gitignore, hook chặn đọc. Template: `inventory.ini.example`.
- Hosts: `[vm1_web]` ctf-vm1-web, `[vm2_challenge]` ctfd-vm2-challenge.
- Mọi play đều `become: yes`.

### Chế độ SSM (MẶC ĐỊNH của hạ tầng này)

Terraform **không tạo `aws_key_pair`** và `sg_web`/`sg_challenge` **không mở port 22** → không thể SSH bằng key.
Vì vậy inventory dùng connection plugin `amazon.aws.aws_ssm` với `ansible_host` = **instance ID** (không chứa IP nào):

```ini
[all:vars]
ansible_connection=amazon.aws.aws_ssm
ansible_aws_ssm_region=ap-southeast-1
ansible_aws_ssm_bucket_name=<terraform output s3_bucket_name>
ansible_aws_ssm_timeout=120
ansible_python_interpreter=/usr/bin/python3
```

Yêu cầu control node (đã cài sẵn): collection `amazon.aws`, `boto3`, và **binary `session-manager-plugin`**
(plugin **bắt buộc** binary này — tự tìm trong `PATH` hoặc `/usr/local/bin/session-manager-plugin`; đã cài trong WSL).

⚠️ Plugin SSM **bỏ qua `ansible_user`/`remote_user`** (dùng `become_user` thay thế). Session chạy bằng
`ssm-user` do SSM Agent tạo, tài khoản này có sudo NOPASSWD → `become: yes` hoạt động.

Transfer file (`copy`/`template`) đi qua **presigned URL + curl** trên managed node → control node cần quyền
`s3:PutObject/GetObject` trên bucket, **instance role KHÔNG cần quyền S3**. `curl` có sẵn trên Ubuntu AMI.

Chạy từ **WSL Ubuntu** (Windows không chạy được ansible-core làm control node — thiếu module `fcntl`):
```bash
wsl -d Ubuntu -- bash -lc "cd /mnt/d/ctfd-platform-2026 && ansible-playbook -i ansible/aws/inventory.ini <playbook> -C --diff"
```

## Thứ tự + nội dung playbook

| # | Playbook | Mục đích chính |
|---|---|---|
| 1 | `common/mtls_setup.yml` | Sinh & phân phối CA/cert giữa 2 VM (tunnel FRP hiện là kênh mã hoá chính cho Docker API) |
| 2 | `common/vm2_challenge.yml` | Docker (get.docker.com), docker-socket-proxy **loopback-only** `127.0.0.1:2376→2375` với allowlist: CONTAINERS, POST, SERVICES, SWARM, TASKS, EVENTS, NETWORKS, ALLOW_START/STOP/RESTARTS, INFO, PING, VERSION. tcpdump `docker0` rotate `-G 1800 -W 48`. K3s `v1.28.2+k3s1` + chờ node Ready (retry 12×10s) |
| 3 | `aws/vm1_web.yml` | Install nginx/docker/**docker compose v2** (`docker-compose-v2`; gói v1.29.2 hỏng `KeyError: 'ContainerConfig'` khi recreate trên Engine 29 → playbook tự gỡ v1)/aws cli; tạo `/opt/ctfd/{themes,uploads,logs,redis,postgres}` (uploads **UID 1001**); truyền theme qua **1 file tar.gz** (loại `node_modules` — copy từng file qua SSM treo vô hạn); sinh secrets trên VM vào `/opt/ctfd/.env` (0600, `openssl rand -hex`) rồi compose thay `${DB_PASSWORD}`/`${CTFD_SECRET_KEY}`; Dockerfile `ctfd/ctfd:latest` + clone ctfd-whale + **pip upgrade docker==7.1.0** (whale pin 4.1.0 lỗi thời) + **`psycopg2-binary`** (bắt buộc cho PostgreSQL, image gốc thiếu) + `USER 1001`; Nginx reverse proxy (+ realip/CF-Ray forensics); frps.ini (7000 control, 7400 dashboard, 8080 vhost, `subdomain_host`); stack: **db (postgres:15-alpine, container — không RDS)** + ctfd + worker + cache redis; CloudWatch Agent; SSM integration |

## Quy tắc vận hành

1. **Luôn dry-run trước**: `ansible-playbook -i inventory.ini <play> -C --diff`.
   > ⚠️ **Giới hạn của check-mode trên host mới (đã gặp 09/2026)**: task cài đặt dùng
   > `creates:` (docker, k3s, aws cli) **không chạy thật** trong check-mode → các task
   > `systemd`/`service` ngay sau đó sẽ **FAIL** kiểu `Could not find the requested service docker`.
   > Đây là artifact của check-mode trên máy trắng, KHÔNG phải lỗi playbook. Cách đọc kết quả:
   > connection + apt + copy/registry đạt là coi như dry-run PASS; các fail tại
   > `Enable Docker service` / `systemd` trên host mới là dự kiến. Chạy thật ngay sau đó.
2. Playbook phải idempotent — các task dùng `creates:` (aws cli, docker, k3s) để tránh re-run phá máy.
3. Sửa `vm1_web.yml` → test cú pháp: `ansible-playbook --syntax-check` (đã allow trong permissions).
4. Không commit `db_password`/`ctfd_secret_key` vào playbook — dùng `--extra-vars` khi chạy hoặc vault.
5. Sau khi playbook vm1 chạy xong mà site chưa lên → xem skill `ctfd-aws-troubleshoot`.

## Thay đổi theme mà không chạy lại playbook

```bash
VM1_ID=$(terraform -chdir=terraform/aws output -raw vm1_instance_id)
aws ssm send-command --instance-ids $VM1_ID \
  --document-name "AWS-RunShellScript" --region ap-southeast-1 \
  --parameters commands=["sudo cp /home/ubuntu/<file>.html /opt/ctfd/themes/ctfd-theme-neubrutalism/templates/","sudo docker exec ctfd_cache_1 redis-cli FLUSHALL"]
```
CTFd cache template trong Redis → **bắt buộc FLUSHALL** sau khi cập nhật template.

---
name: ctfd-aws-deploy
description: Quy trình deploy end-to-end cụm CTFd lên AWS theo đúng thứ tự bắt buộc — terraform apply, tạo inventory, chạy 3 ansible playbook theo thứ tự mtls → vm2 → vm1, rồi trỏ DNS Cloudflare. Dùng khi user yêu cầu deploy/áp dụng hạ tầng, hoặc sau khi đổi code IaC.
---

# Deploy CTFd lên AWS — quy trình chuẩn

## Gate kiểm tra trước khi chạy (bắt buộc)

1. `aws sts get-caller-identity` — đúng account, đúng profile?
2. `terraform -chdir=terraform/aws validate` — code IaC hợp lệ?
3. `terraform.tfvars` tồn tại local với `db_password` mạnh? (KHÔNG đọc nội dung)
4. Ansible đã cài? (`ansible-playbook --version`) — nếu chưa: `.claude/scripts/setup-dev-env.ps1`
5. **Hỏi user: phương án DB (A = PostgreSQL container trên VM1 như playbook hiện tại, B = dùng RDS từ Terraform)** — xem skill `ctfd-aws-architecture`.

## Thứ tự chạy (vi phạm thứ tự = fail)

```bash
# B1 — Provision hạ tầng (10-15 phút, RDS khởi tạo lâu)
terraform -chdir=terraform/aws init
terraform -chdir=terraform/aws plan -var-file=terraform.tfvars   # REVIEW DIFF TRƯỚC
terraform -chdir=terraform/aws apply -var-file=terraform.tfvars

# B2 — Lấy outputs để điền inventory
terraform -chdir=terraform/aws output
# vm1_web_public_ip, vm2_challenge_public_ip, vm1_instance_id, vm2_instance_id,
# rds_endpoint, database_url_ssm_parameter, s3_bucket_name

# B3 — Inventory
cp ansible/aws/inventory.ini.example ansible/aws/inventory.ini
# điền IP VM1/VM2 (agent KHÔNG đọc file này khi đã điền thật)

# B4 — Chờ SSM Agent online (2-3 phút sau khi EC2 boot)
aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=$(terraform -chdir=terraform/aws output -raw vm1_instance_id)" \
  --region ap-southeast-1

# B5 — Ansible theo thứ tự (luôn dry-run -C trước khi chạy thật)
ansible-playbook -i ansible/aws/inventory.ini ansible/common/mtls_setup.yml -C
ansible-playbook -i ansible/aws/inventory.ini ansible/common/mtls_setup.yml
ansible-playbook -i ansible/aws/inventory.ini ansible/common/vm2_challenge.yml -C
ansible-playbook -i ansible/aws/inventory.ini ansible/common/vm2_challenge.yml
ansible-playbook -i ansible/aws/inventory.ini ansible/aws/vm1_web.yml -C
ansible-playbook -i ansible/aws/inventory.ini ansible/aws/vm1_web.yml

# B6 — Cloudflare
# A record: cyberknightgame.site → vm1_web_public_ip, Proxy = ON (cam)
```

## Điều gì mỗi playbook làm

| Playbook | Nội dung |
|---|---|
| `common/mtls_setup.yml` | Phát hành chứng chỉ giữa 2 VM (tunnel FRP đã thay mTLS trực tiếp cho Docker API — vẫn chạy để tương thích) |
| `common/vm2_challenge.yml` | Docker Engine, docker-socket-proxy (loopback :2376→2375, allowlist SERVICES/SWARM/NETWORKS...), tcpdump systemd (rotate 30m, giữ 48 file), K3s v1.28.2+k3s1 |
| `aws/vm1_web.yml` | aws cli, dirs `/opt/ctfd/{themes,uploads,logs,redis,postgres}`, copy theme, Dockerfile CTFd + whale + `docker==7.1.0`, Nginx, frps.ini (token, subdomain_host), docker-compose (db+ctfd+cache), CloudWatch Agent, `/ctfd/database-url` SSM |

## After-deploy checklist

- [ ] `https://cyberknightgame.site` load được, SSL Cloudflare active
- [ ] Đăng ký admin, đổi password mặc định
- [ ] Test tạo 1 dynamic challenge → instance Whale spin-up được trên VM2
- [ ] `aws logs tail /ctfd/nginx/error --region ap-southeast-1` — không lỗi
- [ ] PCAP ghi vào `/var/log/ctf-pcap/` trên VM2
- [ ] EventBridge schedules xuất hiện (`aws scheduler list-schedules`)

## Rollback

- Terraform: `terraform -chdir=terraform/aws plan` xem diff, áp lại version trước qua git.
- CTFd app: `docker-compose down && git checkout <tag cũ> && docker-compose up -d --build` trên VM1 qua SSM.
- DB: RDS point-in-time restore (chỉ khi dùng RDS — phương án B).

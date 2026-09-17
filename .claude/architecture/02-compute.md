# 02 — Compute (EC2 + IAM)

> Nguồn sự thật: `terraform/aws/compute.tf`

## AMI

`data aws_ami ubuntu_22_04` — Canonical (`099720109477`), `most_recent`,
pattern `ubuntu-jammy-22.04-amd64-server-*`, HVM SSD.

## VM1 — `ctf-vm1-web` (Web Server)

| Thuộc tính | Giá trị | Lý do |
|---|---|---|
| Instance type | `t3.small` (2 vCPU/2GB) — `var.vm1_instance_type` | CTFd + Redis + Nginx + PostgreSQL container — luyện tập; 2GB chật, theo dõi OOM |
| Subnet | public_1 | cần IP public cho Cloudflare origin |
| SG | `sg_web` | |
| Root volume | 30GB gp3 **encrypted** | |
| Elastic IP | `ctf-vm1-web-eip` (`aws_eip.vm1_web`) | giữ IP cố định cho A record Cloudflare — IP động sẽ đổi mỗi lần stop/start; chi phí public IPv4 ($3.65/tháng) đã tính sẵn dù có EIP hay không |
| IMDSv2 | `required`, **hop-limit 1** | chặn container SSRF đọc IAM token — hàng rào số 1 |

## VM2 — `ctf-vm2-challenge` (Challenge Server)

| Thuộc tính | Giá trị | Lý do |
|---|---|---|
| Instance type | `m7i-flex.large` (2 vCPU/8GB) mặc định — `var.vm2_instance_type` | Docker + K3s + nsjail chạy nhiều instance đồng thời; x86_64. **Account đang ở AWS Free plan → chỉ launch được instance type free-tier-eligible; `t3.large` bị AWS từ chối (`InvalidParameterCombination: not eligible for Free Tier`)** |
| Subnet | public_1 | |
| SG | `sg_challenge` (zero-inbound) | |
| Root volume | 50GB gp3 encrypted | images challenge |
| Spot | khi `is_practice_mode=true` — `instance_market_options`, interruption = **stop** | tiết kiệm ~70%, giữ EBS khi bị interrupt |

## IAM

`aws_iam_role.ctf_vm_role` (trust: ec2.amazonaws.com) → instance profile `ctf-vm-profile`:

| Policy | Mục đích |
|---|---|
| `AmazonSSMManagedInstanceCore` | SSM Session Manager — SSH không cần port 22 |
| `CloudWatchAgentServerPolicy` | đẩy logs lên CloudWatch |
| `AmazonSSMReadOnlyAccess` | đọc SSM parameters (DATABASE_URL) |

⚠️ Không gắn thêm `AmazonEC2FullAccess` hay role rộng — least privilege.

## IMDSv2 — tại sao hop-limit 1

`http_put_response_hop_limit = 1`: token IMDSv2 chỉ lấy được từ hypervisor hop đầu
(hệ điều hành host). Container (thêm 1 network hop) **không lấy được token** → SSRF từ
Web challenge không đánh cắp IAM credentials được. Đây là thiết kế cố ý cho nền tảng
chứa Web Exploitation challenge — tuyệt đối không tăng hop-limit "cho tiện".

## Runtime stack (do Ansible cài)

- VM1: nginx, docker, **docker compose v2** (apt `docker-compose-v2` 2.40.3), awscli, CloudWatch Agent; `/opt/ctfd` (themes, uploads UID 1001, logs, redis, postgres)
- VM2: Docker (get.docker.com), docker-socket-proxy (loopback), tcpdump systemd, K3s `v1.28.2+k3s1`

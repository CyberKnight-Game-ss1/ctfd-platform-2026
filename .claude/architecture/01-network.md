# 01 — Network

> Nguồn sự thật: `terraform/aws/network.tf`, `terraform/aws/variables.tf`

## Topology

| Thành phần | Giá trị | Ghi chú |
|---|---|---|
| VPC `ctf-vpc` | `10.0.0.0/16` | `enable_dns_hostnames/support = true` |
| Internet Gateway `ctf-igw` | gắn VPC | public subnets đi qua đây |
| Public Subnet 1 `ctf-subnet-public-1` | `10.0.1.0/24` @ `${region}a` | `map_public_ip_on_launch = true` — VM1 + VM2 |
| Public Subnet 2 `ctf-subnet-public-2` | `10.0.2.0/24` @ `${region}b` | bắt buộc ≥2 AZ cho RDS subnet group |
| Route table `ctf-public-rt` | `0.0.0.0/0 → IGW` | gắn cả 2 subnets |

## Security Groups (3 nhóm, mô hình "mắc kẽm")

### `sg_web` — VM1
| Hướng | Port | Nguồn | Ý nghĩa |
|---|---|---|---|
| In | 80, 443 | 15 dải Cloudflare IPv4 (hardcode trong `cloudflare_ips`) | chỉ edge truy cập origin |
| In | 7000 | `10.0.0.0/16` (VPC-only) | FRP control channel từ VM2 — không public |
| In | 10000-10100 | `0.0.0.0/0` | FRP challenge ports — bắt buộc public cho gameplay (netcat/dynamic challenge) |
| Out | all | `0.0.0.0/0` | |

### `sg_challenge` — VM2
| Hướng | Port | Nguồn |
|---|---|---|
| In | — | **zero inbound** (Docker API ra loopback, CTFd gọi qua FRP tunnel) |
| Out | all | `0.0.0.0/0` (kéo Docker images) |

### `sg_db` — RDS
| Hướng | Port | Nguồn |
|---|---|---|
| In | 5432 | chỉ `sg_web` (reference, không CIDR) |
| Out | all | |

## Cloudflare allowlist

Biến `cloudflare_ips` (variables.tf) chứa 15 dải IPv4 chính thức của Cloudflare.
**Khi Cloudflare thêm dải mới → update biến này + `terraform apply`**, nếu không
traffic qua edge mới sẽ bị drop tại SG.

## FRP topology (chi tiết dễ nhầm)

```
VM2 frpc ──(control :7000, VPC-only, token)──► VM1 frps
CTFd-Whale (VM1) ──(Docker API request qua tunnel)──► VM2 docker-socket-proxy 127.0.0.1:2376
Player netcat ──(public 10000-10100)──► frps ──► challenge instance trên VM2
frps config: vhost_http_port 8080 · dashboard 7400 (127.0.0.1) · subdomain_host = <ctf_domain>
```
- Token FRP hiện hardcode `secret_frp_token_2026` trong playbook — **phải rotate trước giải thật** (xem 04-security).
- Dashboard 7400 không mở SG (chỉ loopback trên VM1, xem qua SSM tunnel).

## Design notes

- 2 subnets public (không private subnet): RDS vẫn "private" nhờ SG + `publicly_accessible=false`. Trade-off được chấp nhận để tránh NAT Gateway ($32/tháng).
- Challenge ports 10000-10100 là bề mặt public duy nhất ngoài Cloudflare — bọc bằng gameplay (port mapping ngắn hạn, Whale tự cấp phát).

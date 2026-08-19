# Dynamic Challenges – Kubernetes & nsjail

## Tổng quan

VM2 chạy **K3s** (lightweight Kubernetes) để tạo môi trường sandbox cô lập cho từng participant.
Các file cấu hình nằm tại `challenges/k8s/`.

## NetworkPolicy – Cô lập network cho challenge containers

File: [`challenges/k8s/network_policy.yaml`](../../challenges/k8s/network_policy.yaml)

```yaml
# Namespace: pwn
# Ingress: Chỉ nhận traffic từ namespace "gateway" (ingress controller hoặc ttyd gateway)
# Egress:  Chỉ cho phép DNS (UDP 53) tới kube-system
#          → Ngăn reverse shell kết nối ra internet
```

**Áp dụng policy:**
```bash
k3s kubectl apply -f challenges/k8s/network_policy.yaml
```

## nsjail Pod – Sandbox challenge binary

File: [`challenges/k8s/nsjail_pod.yaml`](../../challenges/k8s/nsjail_pod.yaml)

Cấu hình bảo mật đã được áp dụng:
- `allowPrivilegeEscalation: false` — không cho leo thang đặc quyền.
- `runAsUser: 1000` — chạy với user không phải root.
- `capabilities.drop: [ALL]` — drop tất cả Linux capabilities.
- Giới hạn resource: 256Mi RAM, 500m CPU.

**Trong production**, image nên có nsjail pre-installed và challenge binary được run như:
```bash
nsjail --mode l --port 1337 \
  --chroot / \
  --user 1000 --group 1000 \
  --cgroup_mem_max 268435456 \
  --rlimit_cpu 10 \
  -- /challenge
```

## Quản lý K3s trên VM2

```bash
# Xem danh sách pods
k3s kubectl get pods -A

# Xem pods trong namespace pwn
k3s kubectl get pods -n pwn

# Xem logs của một pod
k3s kubectl logs -n pwn pwn-challenge-1

# Xem NetworkPolicy đang áp dụng
k3s kubectl get networkpolicies -n pwn

# Xóa và tái tạo một pod (reset challenge)
k3s kubectl delete pod pwn-challenge-1 -n pwn
k3s kubectl apply -f challenges/k8s/nsjail_pod.yaml
```

## PCAP Traffic Analysis

tcpdump chạy như systemd service trên VM2, capture traffic trên interface `docker0`.

```bash
# Kiểm tra service đang chạy
systemctl status ctf-tcpdump

# Xem các file PCAP đã capture
ls -lh /var/log/ctf-pcap/

# Phân tích PCAP bằng tcpdump
tcpdump -r /var/log/ctf-pcap/20260101-120000.pcap -nn

# Upload PCAP lên S3 (AWS) hoặc GCS (GCP) để phân tích sau
# AWS:
aws s3 cp /var/log/ctf-pcap/ s3://<bucket-name>/pcap/ --recursive

# GCP:
gsutil -m cp /var/log/ctf-pcap/* gs://<bucket-name>/pcap/
```

## Bảo mật lưu ý khi chạy CTF Web Exploitation

1. **Không expose Docker socket trực tiếp** — Luôn dùng `docker-socket-proxy` với mTLS.
2. **IMDSv2 trên AWS EC2** — Đã được bật trong `terraform/aws/compute.tf` (`http_tokens = "required"`).
3. **Firewall/Security Group** — Port 2376 chỉ được mở cho VM1 → VM2, không expose ra internet.
4. **NetworkPolicy K3s** — Ngăn container gọi ra internet (chống reverse shell).
5. **nsjail** — Drop tất cả capabilities, chạy non-root, giới hạn CPU và RAM.

#!/usr/bin/env bash
# ============================================================
# check-vm2.sh — Kiểm tra sức khoẻ VM2 (Challenge Server)
# Chạy qua SSM (không cần SSH):
#   pwsh -File .claude/scripts/ssm-run.ps1 -InstanceId <VM2_ID> -ScriptFile .claude/scripts/check-vm2.sh
# Dùng trong after-deploy checklist (skill ctfd-aws-deploy).
# ============================================================

echo "=== DOCKER ==="
systemctl is-active docker

echo "=== K3S ==="
systemctl is-active k3s

echo "=== K3S NODES ==="
sudo k3s kubectl get nodes --no-headers 2>&1 | head -3

echo "=== CONTAINERS ==="
docker ps --format '{{.Names}} | {{.Status}}'

echo "=== TCPDUMP / PCAP (forensics) ==="
systemctl is-active ctf-tcpdump 2>/dev/null || echo "ctf-tcpdump: n/a"
ls -la /var/log/ctf-pcap/ 2>/dev/null | tail -4

echo "=== FRP CLIENT ==="
systemctl is-active frpc 2>/dev/null || echo "frpc: n/a"

echo "=== DISK ==="
df -h / | tail -1

echo "=== MEM ==="
free -m | head -2
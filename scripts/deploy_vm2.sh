#!/bin/bash
set -e

echo "=== [1/5] Configuring Swap (4GB) ==="
if [ ! -f /swapfile ]; then
    fallocate -l 4G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=4096
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo "Swap created successfully."
else
    echo "Swapfile already exists."
fi

echo "=== [2/5] Updating and installing system packages ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y tcpdump apt-transport-https ca-certificates curl software-properties-common apparmor apparmor-utils

echo "=== [3/5] Installing Docker ==="
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
fi

echo "=== [4/5] Setting up Docker Socket Proxy with mTLS ==="
mkdir -p /etc/docker/certs.d
chmod 755 /etc/docker/certs.d

# Move uploaded certs to proper location
if [ -d /tmp/mtls_certs ]; then
    cp /tmp/mtls_certs/ca.pem /etc/docker/certs.d/ca.pem
    cp /tmp/mtls_certs/server-cert.pem /etc/docker/certs.d/server-cert.pem
    cp /tmp/mtls_certs/server-key.pem /etc/docker/certs.d/server-key.pem
    chmod 444 /etc/docker/certs.d/ca.pem
    chmod 444 /etc/docker/certs.d/server-cert.pem
    chmod 400 /etc/docker/certs.d/server-key.pem
fi

# Stop existing proxy if running
docker stop docker-proxy 2>/dev/null || true
docker rm docker-proxy 2>/dev/null || true

docker run -d \
  --name docker-proxy \
  --restart always \
  --privileged \
  -p 2376:2376 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /etc/docker/certs.d:/run/secrets:ro \
  -e CONTAINERS=1 \
  -e POST=0 \
  -e START=1 \
  -e STOP=1 \
  -e RESTART=1 \
  -e INFO=1 \
  -e TLS_CERT_PATH=/run/secrets/server-cert.pem \
  -e TLS_KEY_PATH=/run/secrets/server-key.pem \
  -e TLS_CA_PATH=/run/secrets/ca.pem \
  -e REQUIRE_TLS=1 \
  tecnativa/docker-socket-proxy

echo "=== [5/5] Setting up tcpdump and K3s ==="
mkdir -p /var/log/ctf-pcap
cat << 'EOF' > /usr/local/bin/capture_ctf_traffic.sh
#!/bin/bash
mkdir -p /var/log/ctf-pcap
exec tcpdump -i docker0 -w '/var/log/ctf-pcap/%Y%m%d-%H%M%S.pcap' -G 1800 -W 48 -Z root
EOF
chmod +x /usr/local/bin/capture_ctf_traffic.sh

cat << 'EOF' > /etc/systemd/system/ctf-tcpdump.service
[Unit]
Description=CTF Packet Capture
After=network.target docker.service
Requires=docker.service

[Service]
ExecStart=/usr/local/bin/capture_ctf_traffic.sh
Restart=on-failure
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ctf-tcpdump
systemctl restart ctf-tcpdump || true

if ! command -v k3s &> /dev/null; then
    echo "Installing K3s..."
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.2+k3s1 sh -
fi

echo "=== VM2 Challenge Server Setup Completed Successfully! ==="

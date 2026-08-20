#!/bin/bash
set -e

echo "=== [1/6] Configuring Swap (4GB) ==="
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

echo "=== [2/6] Updating and installing system packages ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx docker.io docker-compose python3-pip curl

systemctl enable docker
systemctl start docker

echo "=== [3/6] Setting up mTLS Client Certificates ==="
mkdir -p /etc/docker/client-certs
chmod 755 /etc/docker/client-certs
if [ -d /tmp/mtls_certs ]; then
    cp /tmp/mtls_certs/ca.pem /etc/docker/client-certs/ca.pem
    cp /tmp/mtls_certs/cert.pem /etc/docker/client-certs/cert.pem
    cp /tmp/mtls_certs/key.pem /etc/docker/client-certs/key.pem
    chmod 444 /etc/docker/client-certs/ca.pem
    chmod 444 /etc/docker/client-certs/cert.pem
    chmod 400 /etc/docker/client-certs/key.pem
fi

echo "=== [4/6] Creating CTFd directories and copying themes ==="
mkdir -p /opt/ctfd/themes /opt/ctfd/uploads /opt/ctfd/logs /opt/ctfd/redis /opt/ctfd/postgres
chown -R 1001:1001 /opt/ctfd/uploads /opt/ctfd/logs

if [ -d /tmp/themes ]; then
    cp -r /tmp/themes/* /opt/ctfd/themes/
fi

echo "=== [5/6] Writing docker-compose.yml and starting stack ==="
SECRET_KEY=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)
DB_PASS="CyberKnightCTF_DB_$(head -c 8 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 12)"

cat << EOF > /opt/ctfd/docker-compose.yml
version: '3'
services:
  db:
    image: postgres:15-alpine
    restart: always
    environment:
      - POSTGRES_USER=ctfd
      - POSTGRES_PASSWORD=${DB_PASS}
      - POSTGRES_DB=ctfd
    volumes:
      - /opt/ctfd/postgres:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ctfd"]
      interval: 10s
      timeout: 5s
      retries: 5

  ctfd:
    image: ctfd/ctfd:latest
    restart: always
    ports:
      - "8000:8000"
    environment:
      - SECRET_KEY=${SECRET_KEY}
      - UPLOAD_FOLDER=/var/uploads
      - DATABASE_URL=postgresql://ctfd:${DB_PASS}@db:5432/ctfd
      - REDIS_URL=redis://cache:6379
      - WORKERS=4
      - LOG_FOLDER=/var/log/CTFd
      - ACCESS_LOG=-
      - ERROR_LOG=-
      - REVERSE_PROXY=True
    volumes:
      - /opt/ctfd/logs:/var/log/CTFd
      - /opt/ctfd/uploads:/var/uploads
      - /opt/ctfd/themes/ctfd-theme-neubrutalism:/opt/CTFd/CTFd/themes/ctfd-theme-neubrutalism
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_started

  cache:
    image: redis:4
    restart: always
    volumes:
      - /opt/ctfd/redis:/data

  worker:
    image: ctfd/ctfd:latest
    user: root
    restart: always
    command: ["opt/CTFd/ping.sh", "redis:6379", "worker"]
    environment:
      - SECRET_KEY=${SECRET_KEY}
      - UPLOAD_FOLDER=/var/uploads
      - DATABASE_URL=postgresql://ctfd:${DB_PASS}@db:5432/ctfd
      - REDIS_URL=redis://cache:6379
      - WORKERS=1
      - LOG_FOLDER=/var/log/CTFd
      - ACCESS_LOG=-
      - ERROR_LOG=-
      - REVERSE_PROXY=True
    volumes:
      - /opt/ctfd/logs:/var/log/CTFd
      - /opt/ctfd/uploads:/var/uploads
    depends_on:
      - ctfd
      - cache
EOF

cd /opt/ctfd
if command -v docker-compose &> /dev/null; then
    docker-compose pull
    docker-compose up -d
else
    docker compose pull
    docker compose up -d
fi

echo "=== [6/6] Configuring Nginx Reverse Proxy ==="
cat << 'EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    client_max_body_size 200M;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

nginx -t
systemctl restart nginx
systemctl enable nginx

echo "=== VM1 Web Server Setup Completed Successfully! ==="

#!/usr/bin/env bash
# Configure the two FRPC clients required by CTFd-Whale.
#
# 1. frpc (host network) forwards the loopback-only Docker socket proxy.
# 2. frpc-router joins the Whale overlay so its dynamic HTTP rules can resolve
#    services named <user_id>-<instance_uuid>.

set -euo pipefail

: "${FRP_SERVER_ADDR:?Set FRP_SERVER_ADDR to the VM1 private IP}"
: "${FRP_TOKEN:?Set FRP_TOKEN to the FRPS token}"

FRP_IMAGE="${FRP_IMAGE:-glzjin/frp}"
FRP_OVERLAY_NETWORK="${FRP_OVERLAY_NETWORK:-ctfd_frp_containers}"
FRP_BIND_PORT="${FRP_BIND_PORT:-7000}"
DOCKER_PROXY_PORT="${DOCKER_PROXY_PORT:-2376}"
ROUTER_ADMIN_PORT="${ROUTER_ADMIN_PORT:-7402}"

if ! docker info --format '{{.Swarm.LocalNodeState}}' | grep -qx active; then
  echo "Docker Swarm must be active before configuring the FRPC router." >&2
  exit 1
fi

if ! docker network inspect "$FRP_OVERLAY_NETWORK" >/dev/null 2>&1; then
  docker network create --driver overlay --attachable "$FRP_OVERLAY_NETWORK"
fi

install -d -m 700 /opt/frpc /opt/frpc-router
umask 077

printf '%s\n' \
  '[common]' \
  "server_addr = $FRP_SERVER_ADDR" \
  "server_port = $FRP_BIND_PORT" \
  "token = $FRP_TOKEN" \
  '' \
  '[docker-api]' \
  'type = tcp' \
  'local_ip = 127.0.0.1' \
  "local_port = $DOCKER_PROXY_PORT" \
  'remote_port = 2376' \
  'use_encryption = true' \
  'use_compression = true' \
  '' \
  '[frpc-admin]' \
  'type = tcp' \
  'local_ip = 127.0.0.1' \
  "local_port = $ROUTER_ADMIN_PORT" \
  'remote_port = 7401' \
  'use_encryption = true' \
  > /opt/frpc/frpc.ini

printf '%s\n' \
  '[common]' \
  "server_addr = $FRP_SERVER_ADDR" \
  "server_port = $FRP_BIND_PORT" \
  "token = $FRP_TOKEN" \
  'admin_addr = 0.0.0.0' \
  'admin_port = 7400' \
  > /opt/frpc-router/frpc.ini

chmod 600 /opt/frpc/frpc.ini /opt/frpc-router/frpc.ini

docker rm -f frpc frpc-router >/dev/null 2>&1 || true

docker run -d \
  --name frpc-router \
  --restart always \
  --network "$FRP_OVERLAY_NETWORK" \
  -p "127.0.0.1:${ROUTER_ADMIN_PORT}:7400" \
  -v /opt/frpc-router/frpc.ini:/etc/frp/frpc.ini:ro \
  "$FRP_IMAGE" frpc -c /etc/frp/frpc.ini

docker run -d \
  --name frpc \
  --restart always \
  --network host \
  -v /opt/frpc/frpc.ini:/etc/frp/frpc.ini:ro \
  "$FRP_IMAGE" frpc -c /etc/frp/frpc.ini

sleep 3
curl --fail --silent http://127.0.0.1:"$ROUTER_ADMIN_PORT"/api/status >/dev/null
curl --fail --silent http://127.0.0.1:"$DOCKER_PROXY_PORT"/_ping >/dev/null
echo "FRPC router and private Docker tunnel are ready."

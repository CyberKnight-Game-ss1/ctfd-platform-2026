-- CTFd-Whale production settings for the CyberKnight FRP topology.
-- Docker traffic is HTTP only inside an encrypted FRP TCP tunnel; it is never
-- published by VM2. Change the private address and token together if the
-- deployment topology changes.

UPDATE config SET value='http://frps:2376' WHERE `key`='whale:docker_api_url';
UPDATE config SET value='0' WHERE `key`='whale:docker_use_ssl';

-- This must point to the FRPC admin API, tunneled from VM2 through FRPS.
-- FRPS dashboard port 7400 is not a valid CTFd-Whale router endpoint.
UPDATE config SET value='http://frps:7401' WHERE `key`='whale:frp_api_url';

-- Keep only the FRPC common block here. CTFd-Whale appends one HTTP/TCP
-- section per active instance; do not place the Docker API tunnel here.
UPDATE config
SET value=CONCAT(
  '[common]\n',
  'server_addr = 10.0.1.146\n',
  'server_port = 7000\n',
  'token = 32ed2459dba0200a577b595d4f952d417794c4bd47ae4160\n',
  'admin_addr = 0.0.0.0\n',
  'admin_port = 7400\n'
)
WHERE `key`='whale:frp_config_template';

-- The attachable overlay lets the FRPC router resolve Whale service names.
UPDATE config SET value='ctfd_frp_containers' WHERE `key`='whale:docker_auto_connect_network';
UPDATE config SET value='linux-1' WHERE `key`='whale:docker_swarm_nodes';

-- Production wildcard DNS. Do not leave the local-development default
-- 127.0.0.1.nip.io, or instance links will resolve to the player's machine.
UPDATE config SET value='cyberknightgame.site' WHERE `key`='whale:frp_http_domain_suffix';
UPDATE config SET value='80' WHERE `key`='whale:frp_http_port';
UPDATE config SET value='0' WHERE `key`='whale:refresh';

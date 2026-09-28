#!/usr/bin/env bash
# Validate every nginx config in the repo with `nginx -t` inside a pinned
# container image (no nginx install needed on the runner).
#
# Two things are handled here that plain `nginx -t` would trip on:
#   1. configs behind a reverse proxy reference container DNS names
#      (python-app, backend-api) which nginx resolves at config-load time;
#      `--add-host <name>:127.0.0.1` gives nginx a resolvable name. This is
#      config-test only - nginx never actually connects.
#   2. HTTPS / mTLS configs reference cert/key files, so the matching
#      (self-signed, demo) files from the homework are mounted at the exact
#      paths the configs expect.
set -euo pipefail

NGINX_IMAGE="nginx:1.27-alpine"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0

# validate <target-in-container> <conf-relative-to-repo-root> [extra docker run args...]
validate() {
  local target="$1"
  local conf="$2"
  shift 2
  echo "== nginx -t: $conf"
  if ! docker run --rm -v "$REPO_ROOT/$conf:$target:ro" "$@" "$NGINX_IMAGE" nginx -t; then
    fail=1
  fi
}

echo "nginx image: $NGINX_IMAGE"
docker pull -q "$NGINX_IMAGE"

# --- full main configs (mounted as /etc/nginx/nginx.conf) --------------------

validate /etc/nginx/nginx.conf \
  HW_L3_01_Docker/ManiNava_docker_01/07_sample_project/nginx/nginx.conf \
  --add-host python-app:127.0.0.1

validate /etc/nginx/nginx.conf \
  HW_L3_02_ReverseProxy/ManiNava_reverseproxy_02/02_nginx_basics/nginx.conf \
  --add-host backend-api:127.0.0.1

validate /etc/nginx/nginx.conf \
  HW_L3_02_ReverseProxy/ManiNava_reverseproxy_02/03_nginx_certs/nginx_https.conf \
  -v "$REPO_ROOT/HW_L3_02_ReverseProxy/ManiNava_reverseproxy_02/03_nginx_certs/certs/demo.crt:/etc/nginx/certs/demo.crt:ro" \
  -v "$REPO_ROOT/HW_L3_02_ReverseProxy/ManiNava_reverseproxy_02/03_nginx_certs/certs/demo.key:/etc/nginx/certs/demo.key:ro"

validate /etc/nginx/nginx.conf \
  HW_L3_02_ReverseProxy/ManiNava_reverseproxy_02/04_nginx_admin/nginx_status.conf

validate /etc/nginx/nginx.conf \
  HW_L3_02_ReverseProxy/ManiNava_reverseproxy_02/05_nginx_mtls/nginx_mtls.conf \
  -v "$REPO_ROOT/HW_L3_02_ReverseProxy/ManiNava_reverseproxy_02/05_nginx_mtls/server/server.crt:/etc/nginx/mtls/server/server.crt:ro" \
  -v "$REPO_ROOT/HW_L3_02_ReverseProxy/ManiNava_reverseproxy_02/05_nginx_mtls/server/server.key:/etc/nginx/mtls/server/server.key:ro" \
  -v "$REPO_ROOT/HW_L3_02_ReverseProxy/ManiNava_reverseproxy_02/05_nginx_mtls/ca/rootCA.crt:/etc/nginx/mtls/ca/rootCA.crt:ro"

# --- vhost snippet from L2 (server {} block, dropped into conf.d) ------------

validate /etc/nginx/conf.d/myapp.conf \
  HW_L2_02_Network/ManiNava_network_02/scenario_3_HTTP/nginx_config.conf

exit "$fail"
#!/bin/bash
# 1.2 - Pull the images used by this homework (nginx, haproxy, traefik, python)
SCEN_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCEN_DIR"

docker pull nginx:alpine
docker pull haproxy:alpine
# Docker 29 min API 1.40 -> traefik v3.0/v3.4 docker provider fails, v3.6 works
docker pull traefik:v3.6
docker pull python:3.9-alpine

docker images | grep -E 'nginx|haproxy|traefik|python' > pulled_images.txt

docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" \
    | grep -E 'nginx|haproxy|traefik|python' > images_summary.txt

echo "1.2 pull_images completed. Reports: pulled_images.txt, images_summary.txt"
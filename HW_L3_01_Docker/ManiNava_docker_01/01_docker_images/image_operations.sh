#!/bin/bash

# ============================================================
# 1.2 - Working with Images: pull / tag / inspect
# ============================================================

SCEN_DIR="$(dirname "$(readlink -f "$0")")"
REPORT="$SCEN_DIR/image_operations.txt"

{
  echo "# docker pull nginx:alpine"
  docker pull nginx:alpine
  echo
  echo "# docker images | grep nginx"
  docker images | grep nginx
  echo
  echo "# docker tag nginx:alpine my-nginx:v1.0"
  docker tag nginx:alpine my-nginx:v1.0
  echo
  echo "# docker images | grep -E 'nginx|my-nginx'"
  docker images | grep -E 'nginx|my-nginx'
  echo
  echo "# docker inspect nginx:alpine (Architecture)"
  docker inspect nginx:alpine | grep -A 5 "Architecture"
  echo
  echo "# docker rmi my-nginx:v1.0"
  docker rmi my-nginx:v1.0
} > "$REPORT"

echo "Image operations completed. Report saved to $REPORT"
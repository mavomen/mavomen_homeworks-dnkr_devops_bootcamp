#!/bin/bash

# ============================================================
# 1.3 - Layers & History
# ============================================================

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

docker history nginx:alpine --no-trunc > "$SCEN_DIR/image_history.txt"
docker inspect nginx:alpine | grep -A 10 "RootFS" > "$SCEN_DIR/image_rootfs.txt"
docker image inspect nginx:alpine --format '{{.Size}}' > "$SCEN_DIR/image_size_bytes.txt"

echo "Layers check completed."
echo "  -> image_history.txt"
echo "  -> image_rootfs.txt"
echo "  -> image_size_bytes.txt"
#!/bin/bash

# ============================================================
# 4.3 - Volume backup & restore
# ============================================================

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

docker volume create backup-test
docker volume create restore-test

# seed data into the volume
docker run --rm -v backup-test:/data alpine:latest sh -c 'echo "Important data" > /data/file.txt && echo "More data" > /data/file2.txt'

# backup volume -> host tarball
docker run --rm -v backup-test:/data -v "$SCEN_DIR":/backup alpine:latest tar czf /backup/volume_backup.tar.gz -C /data .
ls -lh "$SCEN_DIR/volume_backup.tar.gz" > "$SCEN_DIR/backup_info.txt"

# restore tarball -> new volume
docker run --rm -v restore-test:/data -v "$SCEN_DIR":/backup alpine:latest tar xzf /backup/volume_backup.tar.gz -C /data
docker run --rm -v restore-test:/data alpine:latest cat /data/file.txt > "$SCEN_DIR/restored_data.txt"

echo "Volume backup/restore completed."
echo "  -> volume_backup.tar.gz"
echo "  -> backup_info.txt"
echo "  -> restored_data.txt"
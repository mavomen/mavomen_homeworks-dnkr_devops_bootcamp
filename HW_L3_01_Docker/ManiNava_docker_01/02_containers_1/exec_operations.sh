#!/bin/bash

# ============================================================
# 2.4 - docker exec & interactive mode
# ============================================================

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

docker rm -f exec-test >/dev/null 2>&1 || true
docker run -d --name exec-test alpine:latest sleep 3600

docker exec exec-test sh -c 'echo "Hello from exec" > /tmp/test.txt'
docker exec exec-test cat /tmp/test.txt > "$SCEN_DIR/exec_output.txt"
docker exec exec-test sh -c 'ps aux' > "$SCEN_DIR/exec_processes.txt"
# -it in a non-tty script prints a warning, hence 2>&1 | head
docker exec -it exec-test sh -c 'echo "Interactive exec test" >> /tmp/test.txt' 2>&1 | head -n 5 >> "$SCEN_DIR/exec_output.txt"

echo "Exec operations completed."
echo "  -> exec_output.txt"
echo "  -> exec_processes.txt"
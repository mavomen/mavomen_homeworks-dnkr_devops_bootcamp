#!/bin/bash

# simulates different flavors of "ssh connection timed out"
# safe to run - only talks to blackhole ips and localhost

echo "== 1. classic timeout: non-routable ip (packets silently dropped) =="
echo '$ timeout 5 ssh -v user@10.255.255.1'
timeout 5 ssh -o ConnectTimeout=4 -v user@10.255.255.1 2>&1 | grep -E "Connecting|connect|timed" | head -4

echo ""
echo "== 2. port closed vs filtered: nothing listening on localhost:2222 =="
echo '$ nc -zv -w 3 localhost 2222'
nc -zv -w 3 localhost 2222 2>&1 || true

echo ""
echo "== 3. hung service: tcp accepts but never speaks ssh =="
nc -l 2229 >/dev/null 2>&1 &
NC_PID=$!
sleep 0.5
echo '$ nc -l 2229 &   # fake server that accepts but sends nothing'
echo '$ timeout 5 ssh -o ConnectTimeout=4 localhost -p 2229'
timeout 5 ssh -o ConnectTimeout=4 -o StrictHostKeyChecking=no localhost -p 2229 2>&1 | head -2
kill $NC_PID 2>/dev/null

echo ""
echo "== 4. quick reachability check helper =="
HOST=${1:-10.255.255.1}
PORT=${2:-22}
echo "\$ nc -zv -w 5 $HOST $PORT"
nc -zv -w 5 "$HOST" "$PORT" 2>&1 || echo "-> unreachable (filtered or down)"

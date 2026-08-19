#!/bin/bash

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

REPORT="$SCEN_DIR/network_performance_diagnosis.txt"
TARGETS="8.8.8.8 1.1.1.1 google.com github.com"

echo "# network performance diagnosis - $(date)" >"$REPORT"

# 1+2. latency + packet loss to a few external servers
{
  echo ""
  echo "# 1+2. latency & packet loss (10 packets each)"
  for t in $TARGETS; do
    echo ""
    echo "== $t =="
    ping -c 10 -q "$t" | tail -2
  done
} >>"$REPORT" 2>&1

# 3. dns resolution time
{
  echo ""
  echo "# 3. dns resolution time"
  for d in google.com github.com stackoverflow.com; do
    # query time from dig stats
    q=$(dig "$d" | awk '/Query time:/ {print $4 " ms"}')
    echo "$d -> $q"
  done
} >>"$REPORT" 2>&1

# 4. mtu check
{
  echo ""
  echo "# 4. mtu check on main interface"
  IFACE=$(ip -o -4 addr show | awk '$2!="lo" {print $2; exit}')
  ip link show "$IFACE" | grep -o 'mtu [0-9]*'
  echo ""
  echo "# ping with dont-fragment, probing max payload:"
  echo "#   1472 bytes payload + 28 ip/icmp header = standard 1500 mtu"
  ping -c 2 -M do -s 1472 8.8.8.8 >/dev/null 2>&1 && echo "1472 bytes: OK (mtu 1500 works)" || echo "1472 bytes: FAILED (mtu < 1500?)"
  ping -c 2 -M do -s 1452 8.8.8.8 >/dev/null 2>&1 && echo "1452 bytes: OK (mtu >= 1480)" || echo "1452 bytes: FAILED"
} >>"$REPORT" 2>&1

# 5. bottleneck summary
{
  echo ""
  echo "# 5. bottleneck analysis"
  worst=$(ping -c 10 -q 8.8.8.8 2>/dev/null | awk -F'/' '/rtt/ {print $5}')
  loss=$(ping -c 10 -q 8.8.8.8 2>/dev/null | grep -o '[0-9]*% packet loss')
  echo "baseline (8.8.8.8): avg ${worst}ms, $loss"
  echo "- if avg > 100ms or loss > 0% -> check wifi signal / isp first"
  echo "- if only some targets are slow -> problem is on that path/provider"
  echo "- if dns times are high (>50ms) -> resolver issue, try 1.1.1.1"
  echo "- if mtu probe fails -> vpn/tunnel overhead, lower interface mtu"
} >>"$REPORT" 2>&1

echo "Diagnosis completed. Report saved to $REPORT"

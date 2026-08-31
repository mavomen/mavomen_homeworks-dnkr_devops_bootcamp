#!/bin/bash

SCEN_DIR="$(dirname "$(readlink -f "$0")")"
REPORT="$SCEN_DIR/performance_report.txt"
SERVER_IP="127.0.0.1"

# start iperf3 server
iperf3 -s -p 5201 >/dev/null 2>&1 &
IPERF_PID=$!
sleep 1

# bandwidth test (tcp)
{
  echo "# TCP Bandwidth Test (iperf3, 10s)"
  iperf3 -c "$SERVER_IP" -p 5201 -t 10 2>&1
} >"$REPORT"

# latency + jitter + packet loss (udp)
{
  echo
  echo "# UDP Test - Latency, Jitter & Packet Loss (100M, 10s)"
  iperf3 -c "$SERVER_IP" -p 5201 -u -b 100M -t 10 2>&1
} >>"$REPORT"

# # alt bandwidth test over eth
# {
#   echo "# Bandwidth Test (10s, TCP)"
#   iperf3 -c 192.168.1.10 -t 10
# } >"$REPORT"

# stop server
kill "$IPERF_PID" 2>/dev/null

echo "Performance test completed. Report saved to $REPORT"

#!/bin/bash

SCEN_DIR="$(dirname "$(readlink -f "$0")")"
REPORT="$SCEN_DIR/security_report.txt"

# top ips by connection count (only those with more than 100 connections)
{
  echo "# IPs with more than 100 connections"
  ss -ntu | awk 'NR>1{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | awk '$1 > 100' | head -n 10
} >"$REPORT"

# ssh failed logins
{
  echo
  echo "# SSH Failed Logins"
  journalctl -u sshd --no-pager 2>/dev/null | grep -i "failed password" | tail -n 20 ||
    sudo grep "Failed password" /var/log/auth.log 2>/dev/null | tail -n 20 ||
    echo "no ssh failed login logs found"
} >>"$REPORT"

# unusual ports (>10000)
{
  echo
  echo "# IPs Connected to Unusual Ports (>10000)"
  ss -ntu | awk 'NR>1{print $5}' | grep -E ':[0-9]{5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -n 10
} >>"$REPORT"

# # alt connection count via netstat
# {
#   echo "# Top IPs by Connection Count (netstat)"
#   netstat -ntu | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -n 10
# } >"$REPORT"

echo "Security report completed. Saved to $REPORT"

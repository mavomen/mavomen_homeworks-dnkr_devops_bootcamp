#!/bin/bash

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

REPORT="$SCEN_DIR/log_analysis_report.txt"
SAMPLE_LOG="/tmp/opencode/sample_auth.log"

# 1. find network-related logs we can read
{
  echo "# network-related log files found in /var/log/"
  ls -lh /var/log/auth.log /var/log/secure /var/log/syslog /var/log/messages /var/log/kern.log 2>/dev/null || true
} >"$REPORT"

# this system (arch) keeps auth logs in the journal and /var/log is not
# readable as normal user -> generate a realistic sample log instead
if [ ! -r /var/log/auth.log ] && [ ! -r /var/log/secure ]; then
  {
    echo ""
    echo "# no readable auth log for this user -> using sample log ($SAMPLE_LOG)"
  } >>"$REPORT"

  mkdir -p "$(dirname "$SAMPLE_LOG")"
  cat >"$SAMPLE_LOG" <<'EOF'
Aug 21 10:01:02 srv sshd[1201]: Accepted publickey for admin from 192.168.1.50 port 51234 ssh2
Aug 21 10:02:11 srv sshd[1305]: Failed password for root from 203.0.113.45 port 41230 ssh2
Aug 21 10:02:14 srv sshd[1306]: Failed password for root from 203.0.113.45 port 41244 ssh2
Aug 21 10:02:18 srv sshd[1307]: Failed password for admin from 203.0.113.45 port 41260 ssh2
Aug 21 10:03:22 srv sshd[1310]: Failed password for invalid user test from 198.51.100.77 port 55012 ssh2
Aug 21 10:04:01 srv sshd[1320]: Accepted password for deploy from 192.168.1.51 port 51300 ssh2
Aug 21 10:05:47 srv sshd[1331]: Failed password for root from 203.0.113.45 port 41300 ssh2
Aug 21 10:06:15 srv sshd[1335]: Invalid user oracle from 198.51.100.77 port 55100
Aug 21 10:07:29 srv sshd[1340]: Failed password for invalid user oracle from 198.51.100.77 port 55120 ssh2
Aug 21 10:08:33 srv sshd[1351]: Connection closed by 192.168.1.50 port 51234 [preauth]
Aug 21 10:09:41 srv sshd[1360]: Failed password for root from 203.0.113.45 port 41380 ssh2
Aug 21 10:10:55 srv sshd[1371]: Failed password for root from 203.0.113.99 port 42000 ssh2
EOF
  LOGFILE="$SAMPLE_LOG"
else
  LOGFILE="/var/log/auth.log"
fi

# 2. last 10 events
{
  echo ""
  echo "# 2. last 10 events"
  tail -n 10 "$LOGFILE"
} >>"$REPORT"

# 3. extract + count ip addresses
{
  echo ""
  echo "# 3. ip addresses in the log (count per ip)"
  grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' "$LOGFILE" | sort | uniq -c | sort -rn
} >>"$REPORT"

# 4. suspicious patterns: multiple failed attempts from same source
{
  echo ""
  echo "# 4. suspicious: failed password attempts grouped by ip"
  grep "Failed password" "$LOGFILE" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' \
    | sort | uniq -c | sort -rn | awk '$1 >= 3 {print "  WARNING: "$1" failed attempts from "$2}'
  echo ""
  echo "# suspicious: invalid users"
  grep -i "invalid user" "$LOGFILE" | head -5
} >>"$REPORT"

echo "Log analysis completed. Report saved to $REPORT"

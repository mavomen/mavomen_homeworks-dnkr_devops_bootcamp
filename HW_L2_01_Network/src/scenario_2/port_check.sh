#!/bin/bash

REPORT="$(dirname "$(readlink -f "$0")")/port_check_report.txt"

# check port 80
{
  echo "# Port 80 (HTTP)"
  timeout 3 nc -zv localhost 80 2>&1 || echo "port 80 is not reachable"
} >"$REPORT"

# check port 22
{
  echo "# Port 22 (SSH)"
  timeout 3 nc -zv localhost 22 2>&1 || echo "port 22 is not reachable"
} >>"$REPORT"

# check port 3306
{
  echo "# Port 3306 (MySQL)"
  timeout 3 nc -zv localhost 3306 2>&1 || echo "port 3306 is not reachable"
} >>"$REPORT"

# # alt telnet check
# {
#   echo "# Port 80 (telnet)"
#   timeout 3 telnet localhost 80 </dev/null 2>&1 || echo "port 80 is not reachable"
# } >>"$REPORT"

echo "Port check completed. Report saved to $REPORT"

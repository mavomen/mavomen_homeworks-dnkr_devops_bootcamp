#!/bin/bash

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

REPORT="$SCEN_DIR/connectivity_report.txt"

# ping 8.8.8.8
{
  echo "# Ping 8.8.8.8 (5 packets)"
  ping -c 5 8.8.8.8
} >"$REPORT"

# ping google.com
{
  echo "# Ping google.com (5 packets)"
  ping -c 5 google.com
} >>"$REPORT"

# dns resolution github.com
{
  echo "# DNS Resolution github.com"
  dig +short github.com
} >>"$REPORT"

# # alt dns resolution
# {
#   echo "# DNS Resolution github.com (nslookup)"
#   nslookup github.com
# } >>"$REPORT"

echo "Connectivity test completed. Report saved to $REPORT"

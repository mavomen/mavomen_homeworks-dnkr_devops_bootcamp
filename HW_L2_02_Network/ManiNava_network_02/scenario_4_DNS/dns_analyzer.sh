#!/bin/bash

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

REPORT="$SCEN_DIR/dns_analysis_report.txt"

DOMAINS="google.com github.com stackoverflow.com linkedin.com"

echo "# DNS analysis - $(date)" >"$REPORT"
echo "# resolver: $(grep -m1 nameserver /etc/resolv.conf | awk '{print $2}')" >>"$REPORT"
echo "" >>"$REPORT"

# table header
{
  printf "%-20s %-16s %-6s %-12s %s\n" "DOMAIN" "IP" "TTL" "QUERY(ms)" "AUTH NS"
  printf "%-20s %-16s %-6s %-12s %s\n" "------" "--" "---" "---------" "-------"
} >>"$REPORT"

for d in $DOMAINS; do
  # ip + ttl from the answer section
  answer=$(dig +noall +answer "$d" A | head -1)
  ip=$(echo "$answer" | awk '{print $5}')
  ttl=$(echo "$answer" | awk '{print $2}')

  # query time from the stats section
  qtime=$(dig "$d" | awk '/Query time:/ {print $4}')

  # authoritative name server
  ns=$(dig +short "$d" NS | head -1)

  printf "%-20s %-16s %-6s %-12s %s\n" "$d" "${ip:-failed}" "${ttl:--}" "${qtime:-?} ms" "${ns:-?}" >>"$REPORT"
done

echo "" >>"$REPORT"
echo "# raw dig output per domain" >>"$REPORT"
for d in $DOMAINS; do
  echo "" >>"$REPORT"
  echo "== $d ==" >>"$REPORT"
  dig "$d" >>"$REPORT"
done

echo "DNS analysis completed. Report saved to $REPORT"

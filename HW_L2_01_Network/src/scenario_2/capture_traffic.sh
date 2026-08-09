#!/bin/bash

IFACE="wlp7s0"
SCEN_DIR="$(dirname "$(readlink -f "$0")")"
DURATION=30

# capture http traffic (30s)
sudo timeout "$DURATION" tcpdump -i "$IFACE" port 80 -w "$SCEN_DIR/http_capture.pcap" &
TCPID=$!

# generate http traffic
end=$((SECONDS + DURATION))
while [ "$SECONDS" -lt "$end" ]; do
  curl -s -o /dev/null http://neverssl.com
  curl -s -o /dev/null http://example.com
  sleep 2
done

wait "$TCPID"

# capture dns traffic (30s)
sudo timeout "$DURATION" tcpdump -i "$IFACE" port 53 -w "$SCEN_DIR/dns_capture.pcap" &
DNSPID=$!

# generate dns traffic
end=$((SECONDS + DURATION))
while [ "$SECONDS" -lt "$end" ]; do
  dig +short example.com >/dev/null
  dig +short github.com >/dev/null
  sleep 2
done

wait "$DNSPID"

# # alt continuous capture
# sudo tcpdump -i "$IFACE" 'port 80 or port 53' -w "$SCEN_DIR/all_capture.pcap" -c 100

echo "Traffic capture completed."

#!/bin/bash

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

LOG="$SCEN_DIR/monitoring_log.txt"
INTERVAL=5
SAMPLES="${1:-5}"   # how many samples to take (default 5)

# detect main interface (first non-loopback iface with an ip)
IFACE=$(ip -o -4 addr show | awk '$2!="lo" {print $2; exit}')
[ -z "$IFACE" ] && IFACE=lo

# read rx/tx byte counters for an interface from /proc/net/dev
get_bytes() {
  awk -v i="$1" '$1 ~ i":" {print $2, $10}' /proc/net/dev
}

echo "monitoring $IFACE every ${INTERVAL}s ($SAMPLES samples)..."

PREV_RX=$(get_bytes "$IFACE" | cut -d' ' -f1)
PREV_TX=$(get_bytes "$IFACE" | cut -d' ' -f2)

for n in $(seq 1 "$SAMPLES"); do
  sleep "$INTERVAL"

  CUR_RX=$(get_bytes "$IFACE" | cut -d' ' -f1)
  CUR_TX=$(get_bytes "$IFACE" | cut -d' ' -f2)

  # bandwidth = counter delta over the interval -> KB/s
  DOWN=$(( (CUR_RX - PREV_RX) / INTERVAL / 1024 ))
  UP=$(( (CUR_TX - PREV_TX) / INTERVAL / 1024 ))

  CONNS=$(ss -ntu state established | tail -n +2 | wc -l)

  # top 5 remote ips by connection count
  TOP_IPS=$(ss -ntu state established | tail -n +2 \
            | awk '{print $5}' | sed 's/:[0-9]*$//' | sort | uniq -c \
            | sort -rn | head -5)

  {
    echo "=== sample $n - $(date +%H:%M:%S) ==="
    echo "interface: $IFACE"
    echo "bandwidth: down ${DOWN} KB/s | up ${UP} KB/s"
    echo "active connections: $CONNS"
    echo "top 5 remote ips:"
    echo "$TOP_IPS" | sed 's/^/  /'
    echo ""
  } >>"$LOG"

  # also print live
  echo "[$n] down ${DOWN}KB/s up ${UP}KB/s conns $CONNS"

  PREV_RX=$CUR_RX
  PREV_TX=$CUR_TX
done

echo "done. results appended to $LOG"

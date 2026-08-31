#!/bin/bash

IFACE="wlp7s0"
CONN="$(nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | awk -F: -v d="$IFACE" '$2==d{print $1}')"

# fall back to dhcp
nmcli device set "$IFACE" managed yes
nmcli connection down "$CONN" 2>/dev/null
nmcli connection up "$CONN" 2>/dev/null

# # alt dhcp restart
# ip link set "$IFACE" down
# ip addr flush dev "$IFACE"
# ip link set "$IFACE" up
# dhcpcd "$IFACE"

# restore dns
resolvectl flush-caches
nmcli connection modify "$CONN" ipv4.method auto ipv4.addresses "" ipv4.dns "" 2>/dev/null
nmcli connection up "$CONN" 2>/dev/null

echo "Network reset to DHCP completed."

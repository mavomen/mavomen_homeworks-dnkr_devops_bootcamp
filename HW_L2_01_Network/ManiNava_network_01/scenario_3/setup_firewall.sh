#!/bin/bash

SCEN_DIR="$(dirname "$(readlink -f "$0")")"
RULES="$SCEN_DIR/firewall_rules.txt"

# enable firewall
sudo ufw enable

# allow http
sudo ufw allow 80/tcp

# allow https
sudo ufw allow 443/tcp

# allow ssh from lan only
sudo ufw allow from 192.168.1.0/24 to any port 22

# default: block all other incoming (already ufw default)
sudo ufw default deny incoming
sudo ufw default allow outgoing

# save active rules
sudo ufw status numbered > "$RULES"

# # alt iptables version
# sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
# sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
# sudo iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 22 -j ACCEPT
# sudo iptables -A INPUT -j DROP
# sudo iptables -L -n > "$RULES"

echo "Firewall setup completed. Rules saved to $RULES"

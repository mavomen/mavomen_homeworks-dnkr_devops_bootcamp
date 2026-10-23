#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"
cd "$SUB/04_grafana_install"
log "grafana install"

sudo pacman -S --noconfirm grafana 2>&1 | tail -3

cat > install_grafana.sh << 'EOF'
#!/bin/bash
sudo pacman -S --noconfirm grafana
sudo systemctl enable --now grafana
EOF
chmod +x install_grafana.sh

sudo systemctl enable --now grafana 2>&1 | tail -2
sleep 10
systemctl status grafana --no-pager | head -8 > grafana_status.txt
curl -s http://admin:admin@localhost:3000/api/org 2>&1 | head -c 120 > grafana_initial_setup.md
log "grafana done"

#!/bin/bash
set -e

# ============================================================
# 1.1 - Docker install & version check
# ============================================================
# NOTE (Arch Linux): docker is already installed on this machine,
# so the apt install block below is kept verbatim from the PDF as
# reference only. On Arch the equivalent is:
#
#   sudo pacman -S --needed docker docker-compose
#   sudo systemctl enable --now docker
#   sudo usermod -aG docker "$USER"   # run docker without sudo, re-login after
#
# PDF reference (Ubuntu/Debian):
#   sudo apt update
#   sudo apt install -y docker.io docker-compose
#   sudo systemctl enable docker
#   sudo systemctl start docker
# ============================================================

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

# version check -> docker_version.txt
{
  echo "# Docker version"
  docker --version
  echo
  echo "# docker info (head)"
  docker info | head -n 20
} > "$SCEN_DIR/docker_version.txt"

# status of the daemon + containers -> docker_status.txt
{
  echo "# systemctl status docker"
  systemctl status docker --no-pager | head -n 15
  echo
  echo "# docker ps -a"
  docker ps -a
} > "$SCEN_DIR/docker_status.txt"

echo "Install/status check completed."
echo "  -> docker_version.txt"
echo "  -> docker_status.txt"
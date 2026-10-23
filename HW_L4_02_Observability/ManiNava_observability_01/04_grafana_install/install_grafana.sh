#!/bin/bash
sudo pacman -S --noconfirm grafana
sudo systemctl enable --now grafana

#!/bin/bash

# simple terminal network dashboard, refreshes every 10s
# usage: ./dashboard.sh   (ctrl+c to quit)

while true; do
  clear
  echo -e "\e[32m================ Network Dashboard ================\e[0m"
  echo "updated: $(date)"
  echo ""

  echo -e "\e[33m-- interfaces / ips --\e[0m"
  ip -br addr
  echo ""

  echo -e "\e[33m-- active connections --\e[0m"
  echo "established: $(ss -ntu state established | tail -n +2 | wc -l)"
  echo ""

  echo -e "\e[33m-- open (listening) ports --\e[0m"
  ss -tuln | tail -n +2 | awk '{print $1, $5}' | sort -u
  echo ""

  echo -e "\e[33m-- dns servers --\e[0m"
  grep nameserver /etc/resolv.conf | awk '{print $2}'
  echo ""

  echo -e "\e[33m-- latest 5 log entries --\e[0m"
  if [ -r /var/log/auth.log ]; then
    tail -n 5 /var/log/auth.log
  else
    # no readable log file -> last 5 ssh-ish entries from the journal
    journalctl -n 5 --no-pager -q _COMM=sshd 2>/dev/null || echo "(no readable logs)"
  fi

  sleep 10
done

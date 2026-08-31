#!/bin/bash

AUDIT_DIR="$HOME/exam_results/audit"

mkdir -p "$AUDIT_DIR"

# notes file
echo "# Notes" >"$AUDIT_DIR/notes.txt"

# cwd
{
  echo "# Current Working Directory"
  pwd
} >"$AUDIT_DIR/cwd.txt"

# users: all
{
  echo "# All Users"
  cut -d: -f1 /etc/passwd
} >"$AUDIT_DIR/users.txt"

# users: bash
{
  echo "# Bash Users"
  grep "/bin/bash" /etc/passwd | cut -d: -f1
} >"$AUDIT_DIR/users_bash.txt"

# shell
{
  echo "# Shell Preview"
  sed 's|/bin/bash|/usr/bin/zsh|g' /etc/passwd | head -n 5
} >"$AUDIT_DIR/preview_shell.txt"

# sys info
{
  echo "# System Information"
  uname -a

  if command -v arch >/dev/null 2>&1; then
    arch
  else
    uname -m
  fi

} >"$AUDIT_DIR/sysinfo.txt"

# groups
{
  echo "# Group Summary"
  head -n 3 /etc/group
  tail -n 2 /etc/group
} >"$AUDIT_DIR/summary_group.txt"

# cnf files
{
  echo "# Configuration Files"
  find /etc -type f -name "*.conf" 2>/dev/null
} >"$AUDIT_DIR/files_conf.txt"

# top 10 .logs
{
  echo "# Top 10 Log Files"

  find /var/log -type f -exec du -h {} + 2>/dev/null |
    sort -hr |
    head -n 10
} >"$AUDIT_DIR/logs_top.txt"

# host bak
cp /etc/hosts "$AUDIT_DIR/hosts.bak"
chmod 600 "$AUDIT_DIR/hosts.bak"

{
  echo "# Hosts Permissions"
  ls -l "$AUDIT_DIR/hosts.bak"
} >"$AUDIT_DIR/hosts_perm.txt"

# # untrace
# for file in "$AUDIT_DIR"/*.txt; do
#   name=$(basename "$file")
#
#   if [[ "$name" != "notes.txt" && "$name" != "hosts_perm.txt" ]]; then
#     rm -f "$file"
#   fi
# done

echo "Audit completed."

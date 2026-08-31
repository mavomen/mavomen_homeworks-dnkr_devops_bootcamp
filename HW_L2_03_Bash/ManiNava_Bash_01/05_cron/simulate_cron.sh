#!/bin/bash

# simulate cron: extract only the commands from sample.cron

awk '!/^#/ && NF>=6 { $1=""; $2=""; $3=""; $4=""; $5=""; sub(/^ */, ""); print }' sample.cron > would_run.txt

echo "commands that would run:"
cat would_run.txt

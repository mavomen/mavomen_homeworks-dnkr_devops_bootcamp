#!/bin/bash

# validate cron format: 5 fields + command

while read -r line; do
    # skip comments and empty lines
    case "$line" in
        ""|\#*) continue ;;
    esac

    # five fields + command (6+ whitespace separated tokens)
    if echo "$line" | awk 'NF>=6 {exit 0} {exit 1}'; then
        echo "VALID: $line"
    else
        echo "INVALID: $line"
    fi
done < sample.cron

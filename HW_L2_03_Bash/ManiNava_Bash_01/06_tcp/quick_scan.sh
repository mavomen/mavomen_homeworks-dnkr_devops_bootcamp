#!/bin/bash

# quick port scan for localhost: 22, 80, 443

for port in 22 80 443; do
    if nc -z -w 2 localhost "$port" 2>/dev/null; then
        echo "$port open"
    else
        echo "$port closed"
    fi
done

#!/bin/bash

# system_checker: root check, file existence, error word search

SAMPLE="./sample.txt"

# root or normal user
if [ "$(id -u)" -eq 0 ]; then
    echo "root user"
else
    echo "normal user"
fi

# sample.txt exists?
if [ -f "$SAMPLE" ]; then
    lines=$(wc -l < "$SAMPLE")
    echo "sample.txt exists with $lines lines"
else
    echo "sample.txt not found, creating placeholder"
    echo "error: placeholder" > "$SAMPLE"
fi

# is there error/ERROR in sample.txt?
if grep -qi "error" "$SAMPLE"; then
    echo "WARNING: 'error' found in sample.txt"
else
    echo "no error found in sample.txt"
fi

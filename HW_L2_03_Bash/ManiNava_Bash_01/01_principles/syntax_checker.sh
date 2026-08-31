#!/bin/bash

# Syntax checker for all .sh files in the project

echo "=== Bash Syntax Report ==="
echo "Date: $(date)"
echo "Working dir: $(pwd)"
echo ""

for f in $(find . -name "*.sh"); do
    if bash -n "$f" 2>&1; then
        echo "OK: $f"
    else
        echo "FAIL: $f"
    fi
done

echo ""
echo "=== End of Report ==="

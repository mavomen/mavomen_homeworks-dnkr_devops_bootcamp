#!/bin/bash

# read sample.txt into array with mapfile, write error lines to errors.txt

SAMPLE="./sample.txt"
OUT="./errors.txt"

: > "$OUT"

mapfile -t lines < "$SAMPLE"

for line in "${lines[@]}"; do
    if grep -qi "error" <<< "$line"; then
        echo "$line" >> "$OUT"
    fi
done

echo "errors written to $OUT:"
cat "$OUT"

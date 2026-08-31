#!/bin/bash

# print running process count 3 times, every 5 seconds

count=0

while [ $count -lt 3 ]; do
    count=$((count + 1))
    processes=$(ps aux | wc -l)
    echo "check $count: $processes processes running"
    sleep 5
done

echo "monitoring finished"

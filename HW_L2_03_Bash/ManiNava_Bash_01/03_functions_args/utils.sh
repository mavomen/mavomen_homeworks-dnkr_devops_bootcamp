#!/bin/bash

# simple tool with three functions (hello / count / disk)

say_hello() {
    echo "Hello, $1"
}

count_lines() {
    wc -l < "$1"
}

disk_ok() {
    used=$(df -h / | awk 'NR==2{print $5}' | tr -d '%')
    if [ "$used" -gt "$1" ]; then
        echo "ALERT"
    else
        echo "ok (used ${used}%)"
    fi
}

case "$1" in
    hello)
        say_hello "$2"
        ;;
    count)
        count_lines "$2"
        ;;
    disk)
        disk_ok "$2"
        ;;
    *)
        echo "usage: $0 {hello NAME|count FILE|disk THRESHOLD}"
        ;;
esac

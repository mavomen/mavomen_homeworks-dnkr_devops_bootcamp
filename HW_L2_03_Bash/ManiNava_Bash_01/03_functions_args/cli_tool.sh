#!/bin/bash

# cli tool with getopts: -f FILE, -u USER, -h help

usage() {
    echo "usage: $0 [-f FILE] [-u USER] [-h]"
    echo "  -f FILE   print line count of FILE"
    echo "  -u USER   print welcome message"
    echo "  -h        show this help"
}

while getopts "f:u:h" opt; do
    case "$opt" in
        f)
            if [ -f "$OPTARG" ]; then
                lines=$(wc -l < "$OPTARG")
                echo "$OPTARG has $lines lines"
            else
                echo "error: file $OPTARG not found"
            fi
            ;;
        u)
            echo "Welcome, $OPTARG"
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

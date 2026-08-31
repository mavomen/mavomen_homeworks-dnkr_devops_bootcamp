#!/bin/bash

# Redirect stdout and stderr, print test messages

SCEN_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCEN_DIR"

# Step 1: Create output directory
mkdir -p ./outputs

# Step 2: Set redirects with exec (stdout -> app.log, stderr -> app.err)
exec 1>./outputs/app.log
exec 2>./outputs/app.err

# Step 3: Test messages
echo "this is info"
echo "second info message"
ls /path/that/does/not/exists
echo "third info message"
ls /another/bad/path

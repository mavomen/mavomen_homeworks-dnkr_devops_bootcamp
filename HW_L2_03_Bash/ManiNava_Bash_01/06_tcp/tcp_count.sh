#!/bin/bash

# count LISTEN and ESTABLISHED tcp connections

listen=$(ss -tan | grep -c LISTEN)
established=$(ss -tan | grep -c ESTAB)

echo "LISTEN: $listen"
echo "ESTABLISHED: $established"

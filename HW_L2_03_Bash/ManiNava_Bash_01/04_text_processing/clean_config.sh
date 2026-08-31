#!/bin/bash

# clean config.ini: remove empty lines and comments, replace DEBUG=true

sed -e '/^$/d' -e '/^#/d' -e 's/^DEBUG=true/DEBUG=false/' config.ini > config.clean

echo "wrote config.clean"
cat config.clean

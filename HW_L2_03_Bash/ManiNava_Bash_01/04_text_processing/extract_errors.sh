#!/bin/bash

# extract ERROR lines from app.log into errors.log

sed -n '/ERROR/p' app.log > errors.log

echo "errors written to errors.log:"
cat errors.log

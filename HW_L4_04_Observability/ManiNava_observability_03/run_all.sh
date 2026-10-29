#!/bin/bash
# Run all Observability 3 live sections in order.
# 04/05 are documentation-only sections (no build scripts).
set -e
cd "$(dirname "$0")"

for d in 01_alertmanager_setup 02_alert_rules_basics 03_notifications_routing; do
  if [ -x "$d/build.sh" ]; then
    (cd "$d" && ./build.sh)
  fi
done

# End-to-end InstanceDown demo (section 01) - ~4 minutes.
(cd 01_alertmanager_setup && ./demo_instance_down.sh)

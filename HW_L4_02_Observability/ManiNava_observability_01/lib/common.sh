#!/bin/bash
export HW_DIR="/mnt/hdd/projects/0-shelfs/CodeStorage/06-DevOps_BOOTCAMP/homeworks/HW_L4_02_Observability"
export SUB="$HW_DIR/ManiNava_observability_01"
export CMDLOG="$SUB/commands_history.txt"
: > "$CMDLOG"
log() { echo "$*" >> "$CMDLOG"; }
run() { log "# $1"; log "$2"; eval "$2" >> "$3" 2>&1; echo >> "$3"; }

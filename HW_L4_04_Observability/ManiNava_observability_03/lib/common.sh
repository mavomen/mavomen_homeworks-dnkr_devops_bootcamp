#!/bin/bash
# Shared helpers for ManiNava_observability_03 build scripts.
export HW_DIR="/mnt/hdd/projects/0-shelfs/CodeStorage/06-DevOps_BOOTCAMP/homeworks/HW_L4_04_Observability"
export SUB="$HW_DIR/ManiNava_observability_03"
export CMDLOG="$SUB/commands_history.txt"
log() { echo "$*" >> "$CMDLOG"; }
# run <description> <command> <output-file>: log the command and capture output.
run() { log "# $1"; log "$2"; eval "$2" >> "$3" 2>&1; echo >> "$3"; }

#!/usr/bin/env bash
# Homework structure check.
#
# Every top-level HW_* directory (the bootcamp submission format) must have:
#   1. the assignment PDF
#   2. the outputs file (name ends with _output__maninava.txt) at the HW root
#   3. exactly one ManiNava_* solution directory
#
# Additionally, a solution directory that already follows the L3 convention
# (i.e. contains overview_qa.txt) must contain the full L3 template:
# README.md, overview_qa.txt, commands_history.txt and final_structure.txt.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

shopt -s nullglob
fail=0
total=0

check() { # check <description> <n> with n > 0 meaning PASS
  total=$((total + 1))
  if [ "$2" -gt 0 ]; then
    printf '  [PASS] %s\n' "$1"
  else
    printf '  [FAIL] %s\n' "$1"
    fail=1
  fi
}

hw_dirs=(HW_*)
if [ "${#hw_dirs[@]}" -eq 0 ]; then
  echo "ERROR: no HW_* directories found at repo root"
  exit 1
fi

for d in "${hw_dirs[@]}"; do
  [ -d "$d" ] || continue
  echo "== $d"

  found_pdf=0
  for f in "$d"/*.pdf; do
    [ -f "$f" ] && found_pdf=1 && break
  done
  check "assignment PDF present" "$found_pdf"

  found_out=0
  for f in "$d"/*output__maninava*.txt; do
    [ -f "$f" ] && found_out=1 && break
  done
  check "outputs file (*output__maninava*.txt) present" "$found_out"

  sol_dirs=("$d"/ManiNava_*/)
  check "exactly one ManiNava_* solution dir (found ${#sol_dirs[@]})" "$(( ${#sol_dirs[@]} == 1 ))"

  if [ "${#sol_dirs[@]}" -eq 1 ]; then
    sol="${sol_dirs[0]}"
    echo "   solution dir: ${sol%/}"
    if [ -f "$sol/overview_qa.txt" ]; then
      echo "   L3 template detected -> enforcing full template"
      for req in README.md overview_qa.txt commands_history.txt final_structure.txt; do
        if [ -f "$sol/$req" ]; then
          check "$req present" 1
        else
          check "$req present" 0
        fi
      done
    fi
  fi
done

echo
if [ "$fail" -eq 0 ]; then
  echo "ALL STRUCTURE CHECKS PASSED ($total checks)"
  exit 0
fi
echo "SOME STRUCTURE CHECKS FAILED"
exit 1
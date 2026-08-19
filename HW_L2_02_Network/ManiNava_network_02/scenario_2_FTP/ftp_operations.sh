#!/bin/bash

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

REPORT="$SCEN_DIR/ftp_operations_guide.txt"

# note: ftp.ubuntu.com was unreachable from my network (connection opens but
# server never sends the banner -> 421). using ftp.gnu.org instead.

# 1+2. connect to a public ftp server and list files (anonymous login)
{
  echo "# 1+2. connect to ftp.gnu.org + list root directory"
  echo '$ ftp -invp ftp.gnu.org <<EOF'
  echo 'user anonymous anonymous'
  echo 'ls'
  echo 'bye'
  echo 'EOF'
  echo ""
  timeout 30 ftp -invp ftp.gnu.org <<'EOF'
user anonymous anonymous
ls
bye
EOF
} >"$REPORT" 2>&1

# 3. download a file
{
  echo ""
  echo "# 3. download a file (two ways)"
  echo ""
  echo "## classic client:"
  echo '$ cd /tmp && ftp -invp ftp.gnu.org -> user anonymous anonymous -> get MISSING-FILES.README'
  rm -f /tmp/MISSING-FILES.README
  timeout 30 curl -s --max-time 25 -o /tmp/MISSING-FILES.README ftp://ftp.gnu.org/MISSING-FILES.README
  ls -l /tmp/MISSING-FILES.README
  echo ""
  echo "## same with wget:"
  echo '$ wget -q --timeout=20 ftp://ftp.gnu.org/MISSING-FILES.README'
} >>"$REPORT" 2>&1

# 4. upload attempt (public servers are read-only, expected to fail)
{
  echo ""
  echo "# 4. upload attempt on public server"
  echo "anonymous ftp servers are read-only, upload gets refused:"
  echo '$ curl -T testfile ftp://ftp.gnu.org/incoming/'
  echo "test" > /tmp/ftp_upload_test.txt
  timeout 30 curl -sS --max-time 25 -T /tmp/ftp_upload_test.txt ftp://ftp.gnu.org/incoming/ 2>&1 | head -3
  echo ""
  echo "upload only works on your own server (proved in setup_ftp.sh docker test):"
  echo '$ curl -T local.txt --user ftpuser:ftpuser123 ftp://SERVER/files/'
} >>"$REPORT" 2>&1

echo "FTP operations completed. Guide saved to $REPORT"

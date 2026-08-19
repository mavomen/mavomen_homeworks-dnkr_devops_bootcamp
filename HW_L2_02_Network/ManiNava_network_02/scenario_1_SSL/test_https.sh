#!/bin/bash

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

REPORT="$SCEN_DIR/https_test_report.txt"

# 1. real https request to google.com (verbose headers only)
{
  echo "# 1. HTTPS request to google.com"
  curl -vI https://google.com
} >"$REPORT" 2>&1

# 2. ssl certificate chain
{
  echo ""
  echo "# 2. SSL certificate chain (google.com)"
  echo | openssl s_client -connect google.com:443 -showcerts 2>/dev/null | grep -E "^ [0-9] s:|^   i:|^   v:"
} >>"$REPORT" 2>&1

# 3. tls version used for the connection
{
  echo ""
  echo "# 3. TLS version"
  curl -vI https://google.com 2>&1 | grep -E "SSL connection|TLSv"
} >>"$REPORT" 2>&1

# 4. certificate expiration dates
{
  echo ""
  echo "# 4. Certificate expiration (google.com)"
  echo | openssl s_client -connect google.com:443 2>/dev/null | openssl x509 -noout -dates
} >>"$REPORT" 2>&1

# bonus: negative test against an expired-cert site
{
  echo ""
  echo "# 5. Negative test: expired.badssl.com (should fail verification)"
  curl -vI https://expired.badssl.com 2>&1 | grep -E "expire|problem|SSL certificate verify" | head -5
} >>"$REPORT" 2>&1

echo "HTTPS test completed. Report saved to $REPORT"

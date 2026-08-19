#!/bin/bash

SCEN_DIR="$(dirname "$(readlink -f "$0")")"

REPORT="$SCEN_DIR/http_methods_report.txt"
API="https://jsonplaceholder.typicode.com"

# GET - read a post
{
  echo "# GET $API/posts/1"
  curl -si "$API/posts/1" | head -15
} >"$REPORT" 2>&1

# POST - create a post
{
  echo ""
  echo "# POST $API/posts"
  curl -si -X POST "$API/posts" \
    -H "Content-Type: application/json" \
    -d '{"title":"test","body":"content","userId":1}' | head -15
} >>"$REPORT" 2>&1

# PUT - update a post
{
  echo ""
  echo "# PUT $API/posts/1"
  curl -si -X PUT "$API/posts/1" \
    -H "Content-Type: application/json" \
    -d '{"id":1,"title":"updated","body":"updated body","userId":1}' | head -15
} >>"$REPORT" 2>&1

# DELETE
{
  echo ""
  echo "# DELETE $API/posts/1"
  curl -si -X DELETE "$API/posts/1" | head -12
} >>"$REPORT" 2>&1

# response codes summary (200 / 201 / 204 / 404 / 500)
{
  echo ""
  echo "# status codes summary"
  printf "%-55s -> %s\n" "GET  $API/posts/1" "$(curl -so /dev/null -w '%{http_code}' $API/posts/1)"
  printf "%-55s -> %s\n" "GET  $API/posts/99999 (missing)" "$(curl -so /dev/null -w '%{http_code}' $API/posts/99999)"
  printf "%-55s -> %s\n" "POST $API/posts" "$(curl -so /dev/null -w '%{http_code}' -X POST $API/posts -H 'Content-Type: application/json' -d '{}')"
  printf "%-55s -> %s\n" "PUT  $API/posts/1" "$(curl -so /dev/null -w '%{http_code}' -X PUT $API/posts/1 -d '{}')"
  printf "%-55s -> %s\n" "DEL  $API/posts/1" "$(curl -so /dev/null -w '%{http_code}' -X DELETE $API/posts/1)"
  # jsonplaceholder has no endpoint that fails with 5xx, so force one via httpbin:
  printf "%-55s -> %s\n" "GET  https://httpbin.org/status/500 (forced)" "$(curl -so /dev/null -w '%{http_code}' https://httpbin.org/status/500)"
} >>"$REPORT" 2>&1

echo "HTTP methods test completed. Report saved to $REPORT"

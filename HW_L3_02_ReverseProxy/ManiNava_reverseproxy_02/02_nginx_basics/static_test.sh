#!/bin/bash
# 2.2 - Static site via read-only bind mount (live update demo)
SCEN_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCEN_DIR"
WEB_DIR="$SCEN_DIR/web"

# keep the delivered index.html clean: restore it after the live-update demo
cp "$WEB_DIR/index.html" /tmp/nginx_static_index_orig.html

docker run -d --name nginx-static \
    -p 8080:80 \
    -v "$WEB_DIR:/usr/share/nginx/html:ro" \
    nginx:alpine
sleep 2

curl -i http://localhost:8080/ > static_check.txt

# change on the host -> visible in the container instantly (bind mount)
echo "File modified" >> "$WEB_DIR/index.html"
curl -i http://localhost:8080/ >> static_check.txt

docker stop nginx-static
docker rm nginx-static

# restore original page so the deliverable stays clean
cp /tmp/nginx_static_index_orig.html "$WEB_DIR/index.html"
rm -f /tmp/nginx_static_index_orig.html

echo "2.2 static_test completed. Report: static_check.txt"
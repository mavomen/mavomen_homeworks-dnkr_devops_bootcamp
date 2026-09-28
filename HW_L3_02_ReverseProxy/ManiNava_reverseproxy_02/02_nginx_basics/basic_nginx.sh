#!/bin/bash
# 2.1 - Run a simple nginx container
SCEN_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCEN_DIR"

docker run -d --name nginx-basic -p 8080:80 nginx:alpine
sleep 2

curl -I http://localhost:8080 > nginx_response.txt
docker logs nginx-basic | head -n 10 > nginx_logs.txt
docker inspect nginx-basic | grep -A 5 "NetworkSettings" > nginx_network.txt

docker stop nginx-basic
docker rm nginx-basic

echo "2.1 basic_nginx completed. Reports: nginx_response.txt, nginx_logs.txt, nginx_network.txt"
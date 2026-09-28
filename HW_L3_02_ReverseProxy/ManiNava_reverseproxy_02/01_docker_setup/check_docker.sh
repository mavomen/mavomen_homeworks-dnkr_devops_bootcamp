#!/bin/bash
# 1.1 - Docker environment check
SCEN_DIR="$(dirname "$(readlink -f "$0")")"
cd "$SCEN_DIR"

{
    docker --version
    echo
    docker info | head -n 20
    echo
    echo "=== docker ps -a ==="
    docker ps -a
    echo
    echo "=== docker network ls ==="
    docker network ls
    echo
    echo "=== docker volume ls ==="
    docker volume ls
} > docker_version.txt

{
    echo "=== docker system df ==="
    docker system df
    echo
    echo "=== docker network inspect bridge | head -n 30 ==="
    docker network inspect bridge | head -n 30
} > docker_status.txt

echo "1.1 check_docker completed. Reports: docker_version.txt, docker_status.txt"
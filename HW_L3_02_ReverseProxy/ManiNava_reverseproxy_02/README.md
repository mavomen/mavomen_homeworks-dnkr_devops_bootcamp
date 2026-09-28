# ManiNava Reverse Proxy Homework 02

Reverse proxy homework for the DevOps bootcamp (week 3). All scenarios run
with Docker / Docker Compose on my Arch machine (docker 29.6.0, compose
5.1.4). The three proxy technologies are covered: Nginx (content server +
reverse proxy + HTTPS + mTLS), HAProxy (load balancer) and Traefik
(dynamic reverse proxy with service discovery).

## 1. Short description

The homework builds from the ground up:

- `01` prepare the Docker environment and pull the images;
- `02` basic nginx container, static site via bind mount, and an nginx
  reverse proxy in front of a python backend;
- `03` self-signed certificates + HTTPS (nginx on 443), HTTP vs HTTPS
  comparison;
- `04` nginx admin: `stub_status` module and container log monitoring;
- `05` mTLS: own CA, server + client certificates, nginx with
  `ssl_verify_client on`;
- `06` HAProxy load balancer (roundrobin + health checks) in front of two
  nginx backends;
- `07` Traefik with the Docker provider: automatic routing to `whoami`,
  virtual hosts and the dashboard API.

## 2. How to run

Every sub-task is a script inside its section folder; run the sections in
order 01 -> 07:

```bash
cd ManiNava_reverseproxy_02
./01_docker_setup/check_docker.sh
./01_docker_setup/pull_images.sh
./02_nginx_basics/basic_nginx.sh
./02_nginx_basics/static_test.sh
./02_nginx_basics/proxy_test.sh
./03_nginx_certs/generate_certs.sh
./03_nginx_certs/https_test.sh
./04_nginx_admin/status_test.sh
./04_nginx_admin/log_monitoring.sh
./05_nginx_mtls/generate_certs.sh
./05_nginx_mtls/mtls_test.sh
./06_haproxy/setup_backends.sh
./06_haproxy/haproxy_test.sh
./07_traefik/run_traefik.sh
./07_traefik/advanced_test.sh
```

Each script writes its outputs next to itself and cleans up its own
containers/networks afterwards. The full run transcript is
`ManiNava_reverseproxy_02_output__maninava.txt` at the homework root.

## 3. File structure & role of each section

```
ManiNava_reverseproxy_02/
├── 01_docker_setup/       # env check (docker_version.txt, docker_status.txt) + image pulls
├── 02_nginx_basics/       # basic nginx, static bind-mount site, nginx->python reverse proxy
├── 03_nginx_certs/        # self-signed certs, HTTPS container, http_vs_https.txt
├── 04_nginx_admin/        # stub_status + log monitoring + log_analysis.txt
├── 05_nginx_mtls/         # CA/server/client certs, mTLS nginx, mtls_explanation.txt
├── 06_haproxy/            # two backends, roundrobin LB + health checks
├── 07_traefik/            # compose (traefik+whoami) + advanced virtual hosts/dashboard
├── README.md
├── overview_qa.txt        # whole-homework Q&A recap
├── final_structure.txt    # find output of this folder
└── commands_history.txt   # every docker command I ran
```

## 4. Service access (ports / URLs)

| Section | Container(s)          | Host port -> container | URL                          |
|---------|-----------------------|------------------------|------------------------------|
| 2.1     | nginx-basic           | 8080 -> 80             | http://localhost:8080/      |
| 2.2     | nginx-static          | 8080 -> 80             | http://localhost:8080/      |
| 2.3     | nginx-proxy+backend-api | 8080 -> 80 (backend-api:5000 internal) | http://localhost:8080/, /api |
| 3.2     | nginx-https           | 8443 -> 443            | https://localhost:8443/status (curl -k) |
| 4.1     | nginx-status          | 8090 -> 80             | http://localhost:8090/basic_status |
| 4.2     | nginx-logs            | 8091 -> 80             | http://localhost:8091/     |
| 5.2     | nginx-mtls            | 9443 -> 9443           | https://localhost:9443/ (client cert) |
| 6.1     | backend1 / backend2   | 8080 / 8081 -> 80      | http://localhost:8080/ , 8081/ |
| 6.2     | haproxy-lb            | 9000 -> 9000           | http://localhost:9000/     |
| 7.1     | traefik + whoami      | 8080 -> 80 (web), 8081 -> 8080 (dashboard) | http://localhost:8080/ , :8081/api/rawdata |
| 7.2     | traefik + web1/web2   | 8080 -> 80, 8443 -> 443, 8081 -> 8080 | Host: web1.localhost / web2.localhost on :8080; dashboard :8081/api/http/routers |

## Notes

- The PDF assumes the default `bridge` network for 2.3 and 6.x, but
  Docker's default bridge has **no name resolution**. A user-defined
  network (`rp-net`, `hb-net`) is used instead so the containers reach
  each other by name exactly as the configs intend - the files, names and
  results are unchanged.
- HAProxy config keeps the PDF's `daemon` directive; at runtime haproxy is
  started with `-db` (foreground) so the container stays up.
- Traefik: the PDF pins `traefik:v3.0`, but this machine runs Docker 29.6
  whose daemon dropped support for API versions below 1.40, and Traefik
  older than v3.5 bundles a docker SDK stuck on API 1.24 - the Docker
  provider then never registers routers and every request returns 404.
  I pinned `traefik:v3.6`, which negotiates the API version properly.
  The labels, ports and routing rules are unchanged.
- Self-signed / demo certs are only for local testing, never for
  production.
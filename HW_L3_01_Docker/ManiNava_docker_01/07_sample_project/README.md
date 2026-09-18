# Docker Sample Project

Small demo: a static frontend (nginx) + a python api (http.server),
orchestrated with docker-compose.

## 1. Short description

- nginx serves the static page on port 3000 and proxies /api to the python
  service.
- python-app answers {"message": "Hello from Python API"} on port 8000
  inside the compose network.
- A custom network (sample-project-network) makes name-based resolution
  work between them.

## 2. How to run

```bash
docker-compose up -d --build
# or: ./run_project.sh
```

Stop with `docker-compose down`.

## 3. Files & roles

```
07_sample_project/
├── docker-compose.yml      # service orchestration
├── nginx/nginx.conf        # static root + /api proxy
├── app/app.py              # python http server (API)
├── app/Dockerfile          # python:3.9-alpine image for the API
└── web/index.html          # static frontend
```

## 4. URLs / ports

| Service   | URL                    | Ports                |
|-----------|------------------------|----------------------|
| Frontend  | http://localhost:3000  | host 3000 -> nginx 80 |
| API       | http://localhost:3000/api | nginx proxies -> python-app:8000 |

## Note

The first build failed until I fixed the indentation in app.py - the PDF
version had the tabs stripped, which broke python and made nginx complain
about the upstream host. After rebuilding, /api worked and the service ran
fine. app.py in this folder already has the fix, so it doesnt need any
change to run.
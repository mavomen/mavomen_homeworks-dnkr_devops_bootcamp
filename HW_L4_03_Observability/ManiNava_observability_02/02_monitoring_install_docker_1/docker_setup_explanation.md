# Docker Setup Explanation - Prometheus via Docker (02_monitoring_install_docker_1)

## 1. Why do we use Docker for installing Prometheus?

- No host pollution: Prometheus runs as an isolated container - no binaries,
  systemd units, or users added to the host. The whole install is
  `docker-compose up -d` and is fully removed with `docker-compose down -v`.
- Reproducibility / portability: `prom/prometheus:latest` (ideally a pinned version)
  runs identically on a laptop, a VM, or a server. The `docker-compose.yml` +
  `prometheus.yml` in this folder *are* the environment definition - same files go to
  production.
- Version management & rollbacks: switching Prometheus versions is an image-tag
  change, not a package-manager operation; rolling back is trivial.
- Upgrade isolation: the process is not entangled with host libraries; upgrades
  can't break other host services.
- Fast setup for learning/CI: a throwaway monitoring stack can be started and
  destroyed in seconds, which is exactly what this homework needs.

## 2. What role does the `prometheus_data` volume play?

`prometheus_data` is a named Docker volume mounted at `/prometheus` - Prometheus's TSDB
data directory (set by `--storage.tsdb.path=/prometheus`).

- Persistence across restarts: container filesystems are ephemeral. Without the
  volume, every `docker-compose down`/recreate would wipe all scraped time series; with
  it, history survives container replacement, image upgrades, and host reboots.
- Decouples data from the image: data lifecycle is separate from the container
  lifecycle; you can upgrade `prom/prometheus` and keep the data.
- Named volume management: `docker volume ls`, backup by copying the volume,
  delete with `docker-compose down -v` (destructive!).

## 3. What does the `--web.enable-lifecycle` flag do?

It enables the lifecycle API endpoints on Prometheus's HTTP interface:

- `POST /-/reload` - reloads `prometheus.yml` in place (validation first: invalid config
  → 500 and no change). No restart, no dropped scrapes.
- `POST /-/quit` - graceful shutdown of Prometheus.

Without this flag both endpoints return 403/404 (disabled by default for security).
It is what makes config hot-reload possible:

```bash
curl -X POST http://localhost:9090/-/reload
```

In production you would normally secure the 9090 port (reverse proxy / network policy)
if the lifecycle API is enabled.

## 4. How can we reload the Prometheus config without restarting the container?

Two no-restart options:

1. Lifecycle reload (used here, because of `--web.enable-lifecycle`):
   ```bash
   # edit ./prometheus.yml, then:
   curl -X POST http://localhost:9090/-/reload
   ```
   Prometheus re-reads the config; on success new scrape/evaluate config applies
   immediately. Check readiness with `curl http://localhost:9090/-/ready`.

2. SIGHUP to the process inside the container:
   ```bash
   docker kill --signal=SIGHUP prometheus
   ```
   Same effect (config reload), works even when the lifecycle API is disabled.

What would be the *wrong* way: `docker restart prometheus` - it works, but briefly
interrupts scraping and re-reads the config only because the container starts from
scratch; that is the restart we want to avoid.

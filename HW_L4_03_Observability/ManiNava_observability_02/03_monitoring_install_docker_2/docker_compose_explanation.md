# Docker Compose Explanation - Prometheus + Grafana + Node Exporter (03_monitoring_install_docker_2)

## 1. Why do we use a Docker Network?

In this compose file all three services are attached to a user-defined bridge network
called `monitoring`. That gives:

- Service discovery by container name: inside the `monitoring` network, containers
  can reach each other by name - Prometheus scrapes `node_exporter:9100` and Grafana
  talks to `http://prometheus:9090` as a data source, without ever publishing those
  ports to the host. Docker's embedded DNS resolves the names on the shared network.
- Isolation: the scrape and query traffic stays inside the compose network. Only the
  ports we explicitly publish (`9090`, `3000`, `9100`) are reachable from the host.
- Cleaner architecture: a dedicated network makes the dependency graph explicit and
  allows other stacks (e.g. Alertmanager in the next homework) to join the same network
  later.

Without a shared network the containers would only see each other via published host
ports (or `--link`, which is legacy and deprecated).

## 2. What role does `depends_on` play?

`depends_on: - prometheus` in the Grafana service controls start order:

- `docker-compose up` starts Prometheus before Grafana, so Grafana does not crash at
  boot while trying to provision a data source that does not exist yet.
- On `docker-compose down`, the order is reversed (Grafana stops first).

Important caveat: `depends_on` is about *container start*, not *application readiness*.
It does not wait for Prometheus's HTTP API to answer - that is why the start script
still sleeps/tests endpoints. For real readiness you would use
`depends_on: {condition: service_healthy}` with a `healthcheck` on Prometheus.

## 3. What data do the different volumes store?

| Volume | Mounted at | Content |
|---|---|---|
| `prometheus_data` | `/prometheus` | Prometheus TSDB: all scraped time series (blocks, WAL, head chunks), i.e. node_exporter + Prometheus self metrics history |
| `grafana_data` | `/var/lib/grafana` | Grafana's SQLite DB + provisioning: users, orgs, data sources, dashboards, API keys, plugin config |

Both exist so that data survives container recreation/upgrades. If the volumes were
removed (`docker-compose down -v`), Prometheus would lose all history and Grafana would
lose its dashboards and data sources.

## 4. How can services be restarted separately?

- Restart a single service: `docker-compose restart grafana` - restarts only that
  container; Prometheus and node_exporter keep running.
- Recreate one service after a config change:
  `docker-compose up -d --no-deps --force-recreate prometheus`
- Stop one service only: `docker-compose stop node_exporter`
  (start again with `docker-compose start node_exporter`).
- Compose applies actions per-service: `docker-compose restart <service>` never touches
  the other services; only `docker-compose restart` (no argument) restarts everything.

Typical example from this homework: after editing `prometheus.yml`, reload in place with
`curl -X POST http://localhost:9090/-/reload` instead of restarting at all.

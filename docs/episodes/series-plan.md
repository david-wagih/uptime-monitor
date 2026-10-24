# Series plan: 3 streams, ~2 hours each

Constraints: **$0 cost**, everything local, a private GitHub repo with GitHub-hosted Linux runners,
and **8 GiB** for the container VM (Podman).

| Stream | Theme | You leave with |
|---|---|---|
| **1. Build it** | App → containers → CI with security scanning | A tested app, running in compose, guarded by a CI pipeline |
| **2. Ship it** | Terraform → kind → Helm → Argo CD (GitOps) → secrets | Git push = deploy, with staging and prod in a local cluster |
| **3. Run it** | Metrics, logs, SLOs, alerts → chaos → postmortem | An observable system you have broken and recovered on purpose |

## Stream 1: Build it (CI)
- App walkthrough: twelve-factor config, liveness vs readiness, the worker loop
- Tests with pytest, linting with ruff, security scanning with bandit (`make check`)
- Multi-stage Dockerfile: layer caching, non-root user, small runtime image
- Compose: healthchecks, a one-shot migrate step, memory limits
- GitHub Actions: lint/test → gitleaks + Trivy → build and scan the image
- Free-tier guardrails: $0 budget, concurrency cancellation, path filters, timeouts, SHA-pinned actions

## Stream 2: Ship it (CD and GitOps)
- Terraform (kind + helm providers): the cluster, Traefik with the Gateway API, Argo CD (core install)
- Local image registry for kind (avoids GHCR quotas)
- Helm chart: api and worker Deployments, migrate Job (Argo CD sync hook), Postgres StatefulSet,
  probes wired to `/healthz` and `/readyz`, resource requests and limits
- Argo CD reads the private repo with a read-only deploy key (least privilege)
- `staging` and `prod` namespaces; promotion = a PR that bumps the image tag
- Secrets with Sealed Secrets (encrypted secrets committed to Git)
- Prerequisite: install Terraform (`brew tap hashicorp/tap && brew install hashicorp/tap/terraform`)

## Stream 3: Run it (operate)
- `/metrics` on the api and worker. The worker exports check results, so the monitor monitors too
- Prometheus and Grafana (trimmed kube-prometheus-stack), Loki for logs
- Define an SLO and error budget, with alert rules for it
- Chaos: kill pods, stop Postgres, lower memory limits until pods are OOMKilled
- Roll back with `git revert` (GitOps), then write a blameless postmortem live
- Optional: share the status page with chat through Cloudflare Tunnel (set `UPTIME_ADMIN_TOKEN` first!)

## Memory budget (8 GiB VM)
Measured in stream 1: db + api + worker ≈ 225 MB. Turn on cluster components per stream and
check them with `make ps` / `kubectl top`. Run `make clean` / `make cluster-down` after each stream.

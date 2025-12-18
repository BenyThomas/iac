# Harbor Registry and Supply Chain Security (Epic I)

This guide defines how Harbor is deployed and integrated with the platform supply chain (proxy caching, robot accounts, signing, and gating). Use it alongside the runbook in `runbooks/harbor-supply-chain.md` and the Jenkins template in `pipelines/Jenkinsfile.template`.

## Outcomes
- HA-ready Harbor with TLS, persistent volumes, and backup/restore workflows.
- Projects for each environment/team and proxy caches for upstream registries (Docker Hub, Quay, GHCR).
- Robot accounts governed for CI only, with rotation and least privilege.
- Cosign signing enforced for protected namespaces; unsigned images blocked.
- Vulnerability scanning with environment-specific thresholds and documented exceptions.

## Prerequisites
- RKE2 cluster with vSphere CSI (or NFS/ceph) and ingress (MetalLB + NGINX).
- cert-manager issuers ready for `*.registry.example.com`.
- S3-compatible backup target (minio, on-prem object store) reachable from the cluster.
- DNS `A`/`CNAME` for `harbor.registry.example.com` pointing at the ingress VIP.

## I1 — Deploy Harbor (HA-ready)
1. Add the chart repo and review/update the provided values file (tunable per environment):
   ```bash
   helm repo add harbor https://helm.goharbor.io
   cp platform/harbor/values-ha.yaml platform/harbor/values-ha.local.yaml
   # Edit platform/harbor/values-ha.local.yaml for DNS, storage classes, and passwords
   ```
2. Deploy:
   ```bash
   kubectl -n platform-services create secret tls harbor-tls \
     --cert=/etc/ssl/harbor.crt --key=/etc/ssl/harbor.key
   helm upgrade --install harbor harbor/harbor -n platform-services -f platform/harbor/values-ha.yaml
   kubectl -n platform-services rollout status deploy/harbor-core
   ```
3. Backups: schedule Velero backups with PV snapshots + Harbor database dump and registry export:
   ```bash
   kubectl -n platform-services create configmap harbor-backup-scripts --from-file=backup.sh=platform/harbor/scripts/backup.sh
   # Velero schedule (example)
   velero create schedule harbor-nightly --schedule "0 2 * * *" --include-namespaces platform-services --ttl 168h
   ```
   Restore tests must be executed per release; capture evidence in the change record.

## Projects and namespaces
- Create environment projects: `dev`, `uat`, `prod` (and team-based projects as needed). Enable content trust and immutable tags on `prod`.
- Map Kubernetes namespaces to Harbor projects via image path: `harbor.registry.example.com/<project>/<app>:<tag>`.
- Replication rules push `prod` artifacts to a disaster-recovery Harbor or cloud registry; see [Replication and DR](#replication-and-dr-readiness).

## Replication and DR readiness
1. Register the DR registry in Harbor (`Administration → Registries`) and note the registry ID.
2. Post a replication policy using `platform/harbor/replication-policy.dr.json`, replacing `dest_registry.id` with the DR registry ID and updating the cron trigger if needed:
   ```bash
   curl -u admin:$HARBOR_ADMIN_PASSWORD -X POST https://harbor.registry.example.com/api/v2.0/replication/policies \
     -H 'Content-Type: application/json' -d @platform/harbor/replication-policy.dr.json
   ```
3. Validate replication: push a tagged image to `prod`, trigger a manual execution (`POST /api/v2.0/replication/executions`), and pull the artifact from the DR endpoint. Capture output of `curl .../replication/executions` for evidence.
4. RPO/RTO: schedule runs every 4 hours by default; adjust `trigger.trigger_settings.cron` to meet target RPO. Perform a DR pull/signature verification monthly.

## I2 — Proxy cache configuration
- For each upstream (Docker Hub, ghcr.io, quay.io), create a **proxy cache project** in Harbor. Example via API:
  ```bash
  curl -u admin:$HARBOR_ADMIN_PASSWORD -X POST https://harbor.registry.example.com/api/v2.0/projects \
    -H 'Content-Type: application/json' \
    -d '{"project_name":"dockerhub-proxy","metadata":{"enable_content_trust":"false"},"registry_id":null,"storage_limit":-1,"project_type":"proxy_cache","proxy_cache":{"endpoint":"https://registry-1.docker.io"}}'
  ```
- In Jenkins pipelines, pull all base images through the proxy path: `harbor.registry.example.com/dockerhub-proxy/library/alpine:3.19`.
- Configure rate limit alerts on proxy cache projects and tune cache TTL per upstream rate limits.

## I3 — Robot accounts and credentials
- Create **robot accounts per project** with minimal scopes (pull for proxy projects; push + scan for env projects). Disable human account usage in CI.
- Store robot credentials as Jenkins credentials (`harbor-robot-dev`, `harbor-robot-uat`, `harbor-robot-prod`). Never echo tokens; only pass into `docker login`.
- Rotation policy: rotate quarterly or upon compromise; keep two overlapping robot accounts per project during rotation (`robot-old` disabled after 72h cutover). Document rotation in `runbooks/harbor-supply-chain.md`.

## I4 — Signing and trusted pulls
- CI signs images with Cosign (keyless via Fulcio/rekor, or key pair stored in Jenkins credentials). Publish public key/configmap `cosign-public-key` in `platform-services`.
- Admission controls (Kyverno) verify signatures for namespaces labeled `env=uat` and `env=prod`. Unsigned images are blocked; see `policies/supply-chain/verify-signed-images.yaml`.
- Mirror the public key into GitOps manifests to avoid drift and enable offline verification.

## I5 — Vulnerability scanning and gating
- Harbor Trivy scanner enabled; daily DB updates via cronjob. Enforce `auto_scan: true` on projects.
- Promotion thresholds:
  - `dev`: warn only (block on exploitability metadata if available).
  - `uat`: block `CRITICAL` and `HIGH`.
  - `prod`: block `MEDIUM+` and require zero `CRITICAL`.
- Pipelines fetch the most recent Trivy report and fail builds using the severity map in `pipelines/Jenkinsfile.template`.
- Exceptions: create a Harbor "allowlist" (CVE allowlist) per project with expiry; document approvals in the change record and attach a Jira ticket.

## Monitoring and observability
- Scrape Harbor metrics (`/metrics`) via Prometheus; alert on replication failures, scan failures, cache miss spikes, and registry HTTP 5xx.
- Enable audit logs shipping to the central log stack (e.g., via fluent-bit tailing `harbor-core` logs) to trace robot account actions.

## Disaster recovery and testing
- DR exercises: quarterly restore of Harbor into an isolated namespace using the latest Velero backup + registry export; validate login, projects, and signatures. Replication drills are detailed above and in `runbooks/harbor-supply-chain.md`.
- Keep offline export of signing public keys and proxy cache endpoints to speed up cold-site recovery.

# Runbook: Harbor Registry + Supply Chain Security (Epic I)

Use this runbook to deploy Harbor and enforce image supply chain controls across dev/uat/prod.

## Prerequisites
- Platform cluster reachable with kubeconfig and Helm.
- cert-manager issuers ready for `*.registry.example.com` TLS.
- Storage class for Harbor PVCs (vSphere CSI/NFS) and S3-compatible bucket for backups.
- Jenkins controller with Docker/Podman + Cosign CLI available.

## I1 — Deploy Harbor (HA)
1. Prepare TLS and namespace:
   ```bash
   kubectl create namespace platform-services || true
   kubectl -n platform-services create secret tls harbor-tls --cert=/etc/ssl/harbor.crt --key=/etc/ssl/harbor.key
   ```
2. Deploy with HA values (customize `platform/harbor/values-ha.yaml` or a local copy): `helm upgrade --install harbor harbor/harbor -n platform-services -f platform/harbor/values-ha.yaml`.
3. Validate:
   - `kubectl -n platform-services get pods -w` until all controllers are Ready.
   - `curl -Ik https://harbor.registry.example.com/healthz` returns `200`.
4. Backups:
   - Mount `/backup` for the harbor-core/registry pods or run the jobsidecar with `platform/harbor/scripts/backup.sh`.
   - Create Velero schedule: `velero create schedule harbor-nightly --schedule "0 2 * * *" --include-namespaces platform-services --ttl 168h`.
5. Restore test (quarterly):
   - Restore namespace and PVC snapshots in isolated cluster.
   - Import DB dump and registry tarball; validate logins and pull signed image `harbor.registry.example.com/prod/hello:latest`.

## I1 — Create projects per environment/team
1. Create `dev`, `uat`, `prod` projects (and team projects as required) via UI or API:
   ```bash
   curl -u admin:$HARBOR_ADMIN_PASSWORD -X POST https://harbor.registry.example.com/api/v2.0/projects \
     -H 'Content-Type: application/json' \
     -d '{"project_name":"prod","metadata":{"enable_content_trust":"true","immutable_tag":"true","auto_scan":"true"}}'
   ```
2. Label Kubernetes namespaces with `env=dev|uat|prod` to drive admission policies.

## I2 — Enable proxy cache
1. Create proxy cache projects (`dockerhub-proxy`, `ghcr-proxy`, `quay-proxy`) via API (see `platform/harbor/README.md`).
2. Update Jenkins base images to use proxy paths, e.g. `FROM harbor.registry.example.com/dockerhub-proxy/library/alpine:3.19`.
3. Validate cache hit rate in Harbor UI and set alerts on upstream rate-limit responses.

## I3 — Robot accounts and credentials
1. For each Harbor project, create a robot account scoped to CI actions only:
   ```bash
   curl -u admin:$HARBOR_ADMIN_PASSWORD -X POST https://harbor.registry.example.com/api/v2.0/projects/1/robots \
     -H 'Content-Type: application/json' \
     -d '{"name":"jenkins","disable":false,"duration":0,"level":"project","permissions":[{"kind":"project","namespace": "prod","access":[{"resource":"repository","action":"push"},{"resource":"repository","action":"pull"},{"resource":"artifact","action":"scan"}]}]}'
   ```
2. Store credentials as Jenkins secrets (`harbor-robot-dev|uat|prod`). Never print tokens; use `withCredentials` in pipelines.
3. Rotation: create `jenkins-rotating` robot, update Jenkins credentials, cut traffic over, then delete the old robot after 72h.

## I4 — Enforce signing and trusted pulls
1. Publish Cosign public key to ConfigMap in `platform-services`:
   ```bash
   kubectl -n platform-services create configmap cosign-public-key --from-file=key=cosign.pub
   ```
2. Apply admission policies:
   ```bash
   kubectl apply -f policies/supply-chain/verify-signed-images.yaml
   kubectl apply -f policies/supply-chain/enforce-harbor-registry.yaml
   ```
3. CI signing (Jenkins): use `pipelines/Jenkinsfile.template` which signs `IMAGE_REF` after push and uploads the transparency log entry. Validate signature:
   ```bash
   cosign verify --key k8s://configmap/cosign-public-key/key harbor.registry.example.com/prod/hello:build-123
   ```
4. Smoke test admission: deploy unsigned image into `prod` namespace and expect rejection with Kyverno `verifyImages` violation.

## I5 — Vulnerability scanning and gating
1. Ensure Trivy is enabled and DB up-to-date: `kubectl -n platform-services logs deploy/harbor-trivy | grep Update finished`.
2. Enforce per-environment thresholds in CI via the severity map in `pipelines/Jenkinsfile.template` (dev: CRITICAL, uat: CRITICAL,HIGH, prod: CRITICAL,HIGH,MEDIUM). Example for prod:
   ```bash
   trivy image --severity CRITICAL,HIGH,MEDIUM --exit-code 1 $IMAGE_REF
   ```
3. Validate Harbor auto-scan on push: push image, then check `Vulnerabilities` tab for report completion.
4. Admission attestation (optional stricter gate): apply `policies/supply-chain/vuln-attestation-thresholds.yaml` to require a cosign vulnerability attestation showing zero critical issues in `prod`.
5. Exceptions: add CVE allowlist entry with expiry in Harbor project settings and link to the approved ticket in the change record.

## Evidence collection
- Keep helm release version, commit hash of Jenkinsfile used, and Kyverno policy report output in the change ticket.
- Archive cosign verification output and Harbor scan reports for the promoted artifact tag.

# Naming Standards (Clusters, Namespaces, Projects, DNS, Certificates)

## Clusters
Format: `k8s-<site>-<env>-<seq>`
Examples: `k8s-dar-dev-01`, `k8s-dar-prod-01`

## Node hostnames
Format: `<cluster>-<role><nn>` where role is `cp` or `wk`.
Examples: `k8s-dar-prod-01-cp01`, `k8s-dar-prod-01-wk07`

## Kubernetes namespaces
- lowercase, hyphen-separated, <=63 chars
- Platform: `platform-<component>` (e.g., `platform-argocd`)
- Apps: `<team>-<app>` (e.g., `payments-ledger`)

## Harbor projects
- Environment: `dev`, `uat`, `prod`
- Or team-based: `<team>` when required
Example: `prod/loan-service`

## DNS records (minimum)

| Endpoint | Record | Notes |
|---|---|---|
| Kubernetes API | `api.<cluster>.<domain>` → control-plane VIP/L4 LB | Required before bootstrap; SAN on API serving certs. |
| Ingress apps | `*.apps.<cluster>.<domain>` (wildcard) or per-app FQDNs | Points to ingress VIP/LB; used by HTTP01 challenges. |
| Container registry | `registry.<domain>` | Harbor tier-0 service; SAN on registry certs. |
| GitOps | `argocd.<cluster>.<domain>` | May also expose SSO callback URI. |
| Monitoring | `grafana.<cluster>.<domain>` (HTTPs) and `prometheus.<cluster>.<domain>` (optional) | TLS via cert-manager; scoped to monitoring users only. |

### DNS ownership and change control
- Ownership: Platform team owns API/ingress records; Security approves TLS/PKI alignment; Network/DNS ops owns zone delegation and record creation in authoritative DNS.
- Change process: PR against infra-as-code DNS repo (or ITSM change) with:
  - Record type/TTL/targets and environment scope (dev/uat/prod)
  - Evidence of matching certificate SANs (cert-manager issuer + `Certificate` manifest)
  - Rollback plan and coordination window for VIP/LB IP changes
- Automation: Argo CD app for DNS (ExternalDNS or provider SDK) may manage ingress hostnames; manual records still tracked via PRs to preserve auditability.

## Certificates
- CN/SAN must match DNS.
- Issued by enterprise PKI or approved internal CA.
- Rotation tracked with defined renewal windows.

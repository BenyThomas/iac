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

| Endpoint | Record | Target / Notes |
|---|---|---|
| Kubernetes API | `api.tcbbank.co.tz` | VIP for the control-plane HA endpoint (NAT/forwarded to `172.25.2.40`) and SAN on API certs. |
| Ingress apps | `*.apps.tcbbank.co.tz` | Wildcard to the ingress VIP (NAT to ingress LB IP range). |
| Container registry | `registry.tcbbank.co.tz` | Harbor ingress VIP; TLS uses the wildcard `tcbbank.co.tz` certificate. |
| GitOps | `argocd.tcbbank.co.tz` | Exposed via ingress; update SSO callbacks to this host. |
| Monitoring | `grafana.tcbbank.co.tz` and `prometheus.tcbbank.co.tz` | HTTPS behind ingress; locked to monitoring users. |

### Node inventory (production RKE2)
- Control plane: `172.25.2.41`, `172.25.2.42`, `172.25.2.43` (fronted by API VIP `172.25.2.40`).
- Workers: `172.25.2.44`–`172.25.2.50`.
- NAT: publish the VIPs/LB addresses above through the DMZ with 1:1 mapping to the same IPs to keep certificates valid for `*.tcbbank.co.tz`.

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

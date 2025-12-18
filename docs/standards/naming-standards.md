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
- API: `api.<cluster>.<domain>`
- Ingress: `*.apps.<cluster>.<domain>` (or per-app FQDNs)
- Registry: `registry.<domain>`
- Argo CD: `argocd.<cluster>.<domain>` (if exposed)

## Certificates
- CN/SAN must match DNS.
- Issued by enterprise PKI or approved internal CA.
- Rotation tracked with defined renewal windows.

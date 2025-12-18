# ADR-0001: Stack Selection (RKE2, Argo CD, Cilium, Harbor on VMs)

## Status
Accepted

## Decision
- Kubernetes Distribution: RKE2 (HA)
- GitOps: Argo CD
- CNI: Cilium
- Private Registry: Harbor on dedicated vSphere VMs

## Consequences
- Platform team owns day-2 operations for RKE2/Cilium/Argo/Harbor.
- PKI/TLS plan required for API, registry, and ingress endpoints.
- Backup/DR plans required for etcd, PVs, Harbor, and CI/GitOps services.

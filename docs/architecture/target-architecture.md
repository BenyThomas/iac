# On‑Prem Kubernetes Platform — Target Architecture & Standards
Version: 0.1
Last updated: 2025-12-17

## 1. Purpose and scope
This document defines the target architecture and non‑functional standards for the on‑prem Kubernetes platform.
It is the baseline reference for all environments (dev/uat/prod).

**Stack choice (fixed):**
- Kubernetes distribution: **RKE2**
- GitOps: **Argo CD**
- CNI: **Cilium**
- Private Registry: **Harbor on dedicated vSphere VMs**
- Platform hosting: **VMware vSphere** (primary).

## 2. Cluster topology (10 nodes)
### 2.1 Node roles
- **3 Control Plane nodes (HA)**  
  - RKE2 server role
  - **Stacked etcd**
- **7 Worker nodes**  
  - RKE2 agent role

### 2.2 Control plane HA endpoint
- Stable endpoint via **VIP** (kube-vip) or L4 LB.
- DNS: `api.<cluster>.<domain>` → VIP/LB
- Failover test: 1 control-plane node down; API remains reachable.

## 3. Networking
### 3.1 CNI (Cilium)
- Cilium installed cluster-wide.
- Baseline posture:
  - Default‑deny for selected namespaces
  - Explicit allow rules for DNS, ingress, monitoring, registry access.

### 3.2 Ingress & LoadBalancer (on‑prem)
- Ingress controller provides HTTP(S) routing.
- If Service `LoadBalancer` is required: MetalLB with approved IP pools.

## 4. Storage (vSphere integrations)
- vSphere CPI/CCM + vSphere CSI.
- StorageClasses:
  - `vsphere-fast`
  - `vsphere-standard`
- Validate: provision, expand, snapshot/restore (if required).

## 5. Image registry (Harbor on VMs)
- Harbor runs on dedicated vSphere VMs (tier‑0 service).
- DNS: `registry.<domain>`
- TLS: enterprise PKI preferred; otherwise internal CA distributed to nodes and CI.
- Governance: projects (dev/uat/prod), robot accounts for CI, retention policies.

## 6. GitOps (Argo CD)
- Argo CD manages platform add-ons, policies, and app deployments (recommended via separate app repos).
- Promotion: dev → uat → prod through PR approvals.

## 7. Security (DevSecOps baseline)
- RBAC + least privilege.
- Admission controls:
  - Harbor allowlist (protected namespaces)
  - Block `:latest` in prod; prefer pinned digests
  - Enforce signed images (Cosign) in prod
- TLS everywhere; secrets not stored in plaintext Git.

## 8. Observability
- Metrics: Prometheus + Grafana
- Logs: centralized logging (Loki/ELK)
- Auditing: Kubernetes API audit logs shipped and retained.
- Alerting: on-call routing and SLOs.

## 9. Backups & DR
- etcd snapshots (encrypted, off-cluster)
- PV backups by criticality
- Harbor backups (DB + artifacts + config)
- Restore drills quarterly (minimum).

## 10. Definition of Done (Epic A)
- Architecture doc approved.
- Naming standards and RACI published.
- Repo structure created with placeholders for deployable components and governance controls.

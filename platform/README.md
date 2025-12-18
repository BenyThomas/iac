# Platform

This directory contains configuration and operational guidance for the shared Kubernetes platform services that run on the RKE2 clusters.

## Structure
- `networking/` — CNI, NetworkPolicies, MetalLB, and ingress controller configuration.
- `vsphere/` — vSphere-specific notes for CPI/CSI and VM templates.
- `pki/` — cert-manager deployment patterns, issuers, and TLS standards.
- `identity/` — SSO, RBAC, and access control guidance for platform and app teams.

See the subdirectories for component-specific manifests and runbooks.

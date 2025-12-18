# Networking Stack (Epic F)

Operational and configuration references for the Kubernetes networking layer: CNI, NetworkPolicies, on-prem LoadBalancer (MetalLB), and ingress.

## Components
- **CNI (Cilium):** Helm-managed installation with Hubble observability and baseline NetworkPolicies.
- **NetworkPolicies:** Default-deny posture for critical namespaces plus documented allow rules for platform services.
- **MetalLB:** LoadBalancer implementation for on-prem clusters with L2 or BGP advertisement options.
- **Ingress Controller:** Standardized ingress-nginx deployment with hardened defaults and ingress templates (internal vs external).

## Manifests and values
- Cilium Helm values: `platform/networking/manifests/cilium/values.yaml`
- NetworkPolicies: `policies/networking/default-deny-critical-namespaces.yaml` and `policies/networking/platform-allow-rules.yaml`
- MetalLB address pools and advertisements: `platform/networking/manifests/metallb/address-pool.yaml`
- Ingress controller defaults and templates: `platform/networking/manifests/ingress/ingress-nginx-values.yaml` and `platform/networking/manifests/ingress/templates/standard-ingresses.yaml`

See the per-component docs in this directory for installation and validation guidance. Validation steps for acceptance criteria are captured in `runbooks/networking-acceptance.md`.

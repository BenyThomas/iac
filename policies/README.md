# Policies

Repository of Kubernetes policy artifacts for the on‑prem platform.

## NetworkPolicies (Epic F)
- `networking/default-deny-critical-namespaces.yaml` — default-deny posture for `kube-system`, `ingress-nginx`, `monitoring`, `logging`, and `platform-services` namespaces.
- `networking/platform-allow-rules.yaml` — explicit allow rules for DNS, ingress controllers, Prometheus scrapes, and log shipper egress.

Apply in order (default-deny, then allow-rules):
```bash
kubectl apply -f policies/networking/default-deny-critical-namespaces.yaml
kubectl apply -f policies/networking/platform-allow-rules.yaml
```

Ensure application namespaces are labeled and sized appropriately before applying the posture in production clusters.

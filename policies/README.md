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

## Supply chain (Epic I — Harbor)
- `supply-chain/verify-signed-images.yaml` — Kyverno verifyImages rule enforcing Cosign signatures for Harbor-hosted images in `uat` and `prod` namespaces.
- `supply-chain/enforce-harbor-registry.yaml` — restricts workloads to use Harbor (including proxy cache projects) across `dev/uat/prod`.
- `supply-chain/vuln-attestation-thresholds.yaml` — requires vulnerability attestations with zero criticals in `uat` and zero criticals plus ≤5 highs in `prod`.

Apply after publishing the Cosign public key ConfigMap and labeling namespaces with `env=dev|uat|prod`:
```bash
kubectl -n platform-services create configmap cosign-public-key --from-file=key=cosign.pub
kubectl label ns prod env=prod
kubectl label ns uat env=uat
kubectl apply -f policies/supply-chain/
```

## Admission control (Epic L — Policy enforcement)
- `security/pod-security-baseline.yaml` — blocks privileged pods, host networking, and hostPath mounts while requiring non-root + read-only root filesystems. Allow break-glass via pod annotations `security.platform/psa-exempt=true`, `security.platform/allow-hostnetwork=true`, or `security.platform/allow-hostpath=true`.
- `security/registry-allowlist-and-tags.yaml` — enforces Harbor-only images in protected namespaces (`env=uat|prod` or `security.platform/protected=true`), blocks `:latest` tags in prod, and requires digests for workloads labeled `app.kubernetes.io/tier=critical` or `security.platform/tier=critical`.

Apply after labeling namespaces with `env=dev|uat|prod` and adding `security.platform/protected=true` to platform namespaces (e.g., `platform-services`, `monitoring`, `logging`) as needed:
```bash
kubectl apply -f policies/security/pod-security-baseline.yaml
kubectl apply -f policies/security/registry-allowlist-and-tags.yaml
```

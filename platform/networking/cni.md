# CNI and Network Policy Baseline (Cilium)

Deploy **Cilium** as the cluster CNI with default-deny NetworkPolicies for critical namespaces and explicit allow rules for platform services.

## Install Cilium via Helm
1. Create the namespace and pull charts:
   ```bash
   helm repo add cilium https://helm.cilium.io
   kubectl create namespace kube-system --dry-run=client -o yaml | kubectl apply -f -
   helm upgrade --install cilium cilium/cilium \
     --namespace kube-system \
     --values platform/networking/manifests/cilium/values.yaml
   ```
2. Verify installation:
   ```bash
   kubectl -n kube-system rollout status ds/cilium
   kubectl -n kube-system exec ds/cilium-XXXXX -- cilium status
   ```

## Baseline NetworkPolicies
1. Apply default-deny posture for critical namespaces:
   ```bash
   kubectl apply -f policies/networking/default-deny-critical-namespaces.yaml
   ```
2. Apply allow-rules for platform services (DNS, ingress, monitoring, logging):
   ```bash
   kubectl apply -f policies/networking/platform-allow-rules.yaml
   ```
3. Label application namespaces to opt into the posture as needed (example):
   ```bash
   kubectl label namespace apps tier=app --overwrite
   ```

### Critical namespaces covered
- `kube-system` (Cilium, CoreDNS, metrics-server)
- `ingress-nginx` (ingress controllers)
- `monitoring` (Prometheus, exporters)
- `logging` (log collectors/indexers)
- `platform-services` (Harbor clients, controllers)

### Allow-rule summary
- DNS egress from all protected namespaces to CoreDNS.
- CoreDNS ingress from all namespaces on TCP/UDP 53.
- Ingress controller HTTP/HTTPS exposure with explicit port lists.
- Prometheus scrape allowance within the `monitoring` namespace.
- Log shipper egress to centralized logging endpoints.

| Service | Rule | Source file |
| --- | --- | --- |
| CoreDNS | Allow ingress TCP/UDP 53 from all namespaces | `policies/networking/platform-allow-rules.yaml` |
| DNS clients | Allow egress TCP/UDP 53 from protected namespaces | `policies/networking/platform-allow-rules.yaml` |
| Ingress controller | Allow ingress 80/443 and egress 80/443/8080 | `policies/networking/platform-allow-rules.yaml` |
| Prometheus | Allow TCP 9090 scrapes inside `monitoring` | `policies/networking/platform-allow-rules.yaml` |
| Log shippers | Allow egress to Loki/Elasticsearch endpoints | `policies/networking/platform-allow-rules.yaml` |

## Validation
- Confirm policies are enforced:
  ```bash
  kubectl -n ingress-nginx get networkpolicy
  kubectl -n kube-system get networkpolicy
  ```
- Attempt blocked traffic from a test pod:
  ```bash
  kubectl -n ingress-nginx run tmp --image=registry.k8s.io/busybox:1.36 --restart=Never -- wget -qO- http://kubernetes.default
  # Expected: blocked by default-deny unless allow-rules cover the flow
  ```
- Confirm DNS still works from protected namespaces:
  ```bash
  kubectl -n monitoring exec deploy/prometheus-server -- nslookup kubernetes.default
  ```

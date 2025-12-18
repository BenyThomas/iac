# Runbook: Networking Acceptance (Epic F)

Use this runbook to validate the networking stack: CNI, default NetworkPolicies, MetalLB LoadBalancers, and ingress controllers.

## Prerequisites
- Cluster bootstrapped with RKE2 and kubeconfig available.
- Helm CLI access with credentials to pull charts.
- MetalLB IP pools aligned with the reserved VLAN segments.

## F1 — CNI + NetworkPolicies
1. Install Cilium using the provided values:
   ```bash
   helm upgrade --install cilium cilium/cilium \
     --namespace kube-system \
     --values platform/networking/manifests/cilium/values.yaml
   kubectl -n kube-system rollout status ds/cilium
   kubectl -n kube-system exec ds/cilium-XXXXX -- cilium status
   ```
2. Apply default-deny and allow rules:
   ```bash
   kubectl apply -f policies/networking/default-deny-critical-namespaces.yaml
   kubectl apply -f policies/networking/platform-allow-rules.yaml
   kubectl -n ingress-nginx get networkpolicy
   ```
3. Smoke test isolation vs allowed DNS:
   ```bash
   kubectl -n ingress-nginx run tmp --image=registry.k8s.io/busybox:1.36 --restart=Never -- wget -qO- http://kubernetes.default
   # Expect failure (blocked) unless allow-rules permit the path
   kubectl -n monitoring exec deploy/prometheus-server -- nslookup kubernetes.default
   # Expect success (DNS allowed)
   ```

## F2 — MetalLB LoadBalancer
1. Install the chart and apply pools:
   ```bash
   helm upgrade --install metallb metallb/metallb --namespace metallb-system
   kubectl apply -f platform/networking/manifests/metallb/address-pool.yaml
   kubectl -n metallb-system get pods
   ```
2. Deploy test Service + Deployment (echo server) and confirm IP (use the manifest snippet in `platform/networking/metallb.md`):
   ```bash
   kubectl create namespace lb-test
   # Apply inline manifest from Metallb doc
   ```
   Watch for an assigned IP: `kubectl -n lb-test get svc echo-lb -w`.
3. Test reachability from a routable host: `curl -I http://<allocated-ip>`.
4. Cleanup: `kubectl delete ns lb-test`.

## F3 — Ingress Controller & Patterns
1. Deploy external ingress controller:
   ```bash
   helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
     --namespace ingress-nginx \
     --values platform/networking/manifests/ingress/ingress-nginx-values.yaml \
     --set controller.ingressClassResource.name=external \
     --set controller.service.annotations."metallb\.universe\.tf/address-pool"=lb-external
   kubectl -n ingress-nginx get svc ingress-nginx-controller
   ```
2. (Optional) Deploy internal ingress controller with `ingressClassResource.name=internal` and `lb-internal` pool.
3. Apply sample ingresses after replacing hosts/secrets:
   ```bash
   kubectl create namespace demo
   kubectl -n demo apply -f platform/networking/manifests/ingress/templates/standard-ingresses.yaml
   kubectl -n demo get ingress
   ```
4. Validate routing:
   ```bash
   curl -I https://app.example.com
   curl -I -k https://app.internal.example.com
   ```
5. Inspect NGINX config for headers/timeouts: `kubectl -n ingress-nginx exec deploy/ingress-nginx-controller -- nginx -T | head`.

## Evidence collection
- Save command outputs (kubectl, curl) and allocated IPs into the change ticket.
- Capture screenshots of test application reachability when possible.
- Record the exact chart versions and values used for Cilium, MetalLB, and ingress-nginx.

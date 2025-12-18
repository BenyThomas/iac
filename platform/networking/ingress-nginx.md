# Ingress Controller (ingress-nginx)

Standard ingress layer for HTTP(S) exposure. Defaults prioritize predictable timeouts, secure headers, and ingress class separation for internal vs external entrypoints.

## Deploy controller via Helm
1. Install the public ingress controller (external-facing):
   ```bash
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -
   helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
     --namespace ingress-nginx \
     --values platform/networking/manifests/ingress/ingress-nginx-values.yaml \
     --set controller.ingressClassResource.name=external \
     --set controller.service.annotations."metallb\.universe\.tf/address-pool"=lb-external
   ```
2. Install an internal-only ingress controller (optional) using the same chart but separate release and pool:
   ```bash
   helm upgrade --install ingress-nginx-internal ingress-nginx/ingress-nginx \
     --namespace ingress-nginx \
     --values platform/networking/manifests/ingress/ingress-nginx-values.yaml \
     --set controller.ingressClassResource.name=internal \
     --set controller.ingressClassResource.default=false \
     --set controller.ingressClassResource.controllerValue="k8s.io/ingress-nginx-internal" \
     --set controller.service.annotations."metallb\.universe\.tf/address-pool"=lb-internal \
     --set controller.service.annotations."metallb\.universe\.tf/loadBalancerIPs"=10.20.40.50
   ```

## Controller settings (highlights)
- **Timeouts & limits** configured in `controller.config` and annotations (body size, proxy timeouts, request buffer limits).
- **Security headers** applied cluster-wide via `server-snippet` (HSTS, X-Content-Type-Options, X-Frame-Options, referrer policy).
- **Logging/metrics**: access logs enabled; Prometheus metrics and ServiceMonitor can be added via kube-prometheus-stack.
- **ExternalTrafficPolicy** set to `Local` to preserve client IPs.

Full Helm values are in `platform/networking/manifests/ingress/ingress-nginx-values.yaml`.

## Standard ingress templates
Reference `platform/networking/manifests/ingress/templates/standard-ingresses.yaml` for examples that:
- Split **external** vs **internal** traffic using distinct `ingressClassName` values.
- Enforce TLS with an explicit secret reference.
- Include common annotations for proxy buffer sizes, timeouts, and client body limits.

Apply with:
```bash
kubectl apply -f platform/networking/manifests/ingress/templates/standard-ingresses.yaml
```
Replace hostnames and secret names before applying.

## Validation
- Confirm the controller is Ready and has a MetalLB IP:
  ```bash
  kubectl -n ingress-nginx get svc ingress-nginx-controller
  ```
- Validate routing for both classes:
  ```bash
  kubectl -n demo get ingress
  curl -I https://<external-host>
  curl -I -k https://<internal-host>
  ```
- Check nginx config for applied settings: `kubectl -n ingress-nginx exec deploy/ingress-nginx-controller -- nginx -T | head`.

## Internal vs external separation
- Use distinct `IPAddressPool` objects (`lb-external`, `lb-internal`) and annotate Services accordingly.
- Separate ingress classes prevent applications from unintentionally exposing internal-only hosts to the public LB.
- Optionally, run two ingress-nginx releases (one per class) to isolate config and lifecycle.

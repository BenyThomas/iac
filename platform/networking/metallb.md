# MetalLB (On-Prem LoadBalancer Services)

Deploy MetalLB to provide `LoadBalancer` IPs for services in on-prem clusters. The default pattern uses L2 advertisement; BGP can be enabled for routed connectivity where required.

## Configuration
- **Address pool:** see `platform/networking/manifests/metallb/address-pool.yaml` for the approved IP range and advertisement objects.
- **Mode:**
  - L2 is enabled by default with `L2Advertisement`.
  - BGP can be enabled by adding `BGPPeer` and `BGPAdvertisement` objects that match the same pool.
- **Separation:** Define multiple pools if you need distinct ranges for internal vs external ingress controllers.

## Install via Helm
```bash
helm repo add metallb https://metallb.github.io/metallb
kubectl create namespace metallb-system --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install metallb metallb/metallb --namespace metallb-system
kubectl apply -f platform/networking/manifests/metallb/address-pool.yaml
```

## Validation (acceptance)
1. **Controller health**
   ```bash
   kubectl -n metallb-system get pods -o wide
   ```
2. **Test service obtains IP**
   ```bash
   kubectl create namespace lb-test
   kubectl -n lb-test apply -f - <<'YAML'
   apiVersion: v1
   kind: Service
   metadata:
     name: echo-lb
     annotations:
       metallb.universe.tf/address-pool: lb-external
   spec:
     type: LoadBalancer
     selector:
       app: echoserver
     ports:
       - port: 80
         targetPort: 8080
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: echoserver
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: echoserver
     template:
       metadata:
         labels:
           app: echoserver
       spec:
         containers:
           - name: echo
             image: registry.k8s.io/echoserver:1.10
             ports:
               - containerPort: 8080
   YAML
   kubectl -n lb-test get svc echo-lb -w
   ```
3. **Reachability**
   - From a network that can reach the advertised IP, run: `curl -I http://<allocated-ip>` (expect HTTP 200).
   - Verify failover by deleting the Service pod and watching the LB IP remain allocated.

## Notes
- Document the chosen pool, mode, and upstream routers (for BGP) in change tickets.
- If using BGP, coordinate ASNs/peers with the network team and restrict advertisement to the intended VLAN/VRF.
- Clean up test resources: `kubectl delete ns lb-test`.

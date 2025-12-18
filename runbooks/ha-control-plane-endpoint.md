# Runbook: HA Control-Plane Endpoint (kube-vip or HAProxy + Keepalived)

Purpose: provide a resilient Kubernetes API endpoint with failover validation.

## Prerequisites
- Network: dedicated control-plane VLAN/subnet with routable virtual IP (VIP).
- DNS: record for the API endpoint (for example `api.cluster.local`) pointing at the VIP or load balancer.
- Access: ability to configure either kube-vip on control-plane nodes or HAProxy + Keepalived on a small load balancer tier.
- Certificates: TLS serving certs include the VIP, DNS name, and individual control-plane node names.

## Option A: kube-vip on control-plane nodes
1. Allocate VIP and update DNS A/AAAA record to point at the VIP.
2. Install kube-vip manifest on all three control-plane nodes:
   - Enable ARP mode for L2 or BGP peers for L3 depending on the network.
   - Bind the Kubernetes API port `6443` and advertise the VIP.
   - Set leader election to use the Kubernetes API once it is available; initial bootstrap uses static pod.
3. Validate:
   - `curl -k https://api.cluster.local:6443/version` returns from each node.
   - Temporarily stop kubelet on the elected leader and confirm VIP fails over within 5s.
   - Monitor `kube-vip` logs for successful leader transitions and no gratuitous ARP storm.

## Option B: HAProxy + Keepalived tier
1. Provision two small VMs (or the control-plane nodes themselves if policy permits) and install HAProxy + Keepalived.
2. Configure Keepalived:
   - VIP assigned to the dedicated interface.
   - Health check script hits `https://localhost:6443/healthz`.
   - VRRP authentication configured to prevent spoofing.
3. Configure HAProxy:
   - Frontend `:6443` with TLS passthrough (no re-encryption).
   - Backend servers: all three control-plane nodes on `:6443` with `check-ssl` and `verify none` during bootstrap (enable proper CA when certificates exist).
   - Optionally pin the scheduler to reduce latency.
4. Validate:
   - `curl -k https://api.cluster.local:6443/version` responds through HAProxy.
   - Pull the primary Keepalived node network link and ensure VIP moves to secondary.
   - Take one control-plane node out of HAProxy rotation and confirm requests still succeed.

## Ongoing operations
- Log shipping: send kube-vip or HAProxy/Keepalived logs to central logging.
- Monitoring: alert on loss of VIP, high HAProxy 5xx, or kube-vip leadership churn.
- Change control: any VIP re-IP requires synchronous DNS update and certificate regeneration.

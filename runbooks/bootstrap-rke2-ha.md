# Runbook: Bootstrap RKE2 HA Cluster (3x Control Plane, 7x Workers)

Purpose: reproducible bootstrap for a highly available RKE2 cluster with correct labels/taints.

## Prerequisites
- Network: VIP/DNS for Kubernetes API (`api.tcbbank.co.tz`) is functional (see HA endpoint runbook). VIP `172.25.2.40` fronts the control-plane nodes `172.25.2.41-43`.
- Nodes: 3 control-plane VMs (etcd collocated) and 7 worker VMs (`172.25.2.44-50`) with time sync, SELinux/AppArmor as per baseline hardening, and container runtime prerequisites satisfied.
- Access: SSH with sudo, outbound internet/proxy for RKE2 artifacts, or mirrored registry endpoint.
- Artifacts: `rke2-config.yaml` template stored in Ansible or secret manager (tokens/certs handled securely).

## High-level flow
1. Prepare control-plane node #1.
2. Install RKE2 server on control-plane node #1 and capture the cluster token.
3. Join control-plane nodes #2 and #3.
4. Join 7 worker nodes with labels/taints applied.
5. Validate cluster health and run smoke tests.

## Detailed steps
1. Control-plane #1 bootstrap:
   - Copy `rke2-config.yaml` with `disable: rke2-ingress-nginx` (if using alternative ingress), `tls-san` includes VIP + node hostnames, and `node-taint: "CriticalAddonsOnly=true:NoExecute"`.
   - Enable kube-vip static pod manifest via `manifests/` if using kube-vip.
   - `curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=server sh -`.
   - `systemctl enable --now rke2-server`.
   - Export `/var/lib/rancher/rke2/server/node-token`.
2. Control-plane #2 and #3 join:
   - Configure `rke2-config.yaml` with `server: https://api.tcbbank.co.tz:9345` and same `tls-san` list.
   - Install RKE2 server as above and start the service.
   - Verify `kubectl get nodes -o wide` shows all three `Ready` with `node-role.kubernetes.io/control-plane: ""` and taint `node-role.kubernetes.io/control-plane=true:NoSchedule`.
3. Worker joins (7 nodes):
   - Template `rke2-agent` config pointing at `https://api.tcbbank.co.tz:9345` using the shared token.
   - Install RKE2 agent and start.
   - Apply labels via cloud-init/Ansible after join:
     - Common: `node-role.kubernetes.io/worker=""`.
     - Zonal/hostgroup labels: `topology.kubernetes.io/zone`, `node.kubernetes.io/instance-type`, `kubernetes.io/hostname`.
   - Optional taints for infra nodes (e.g., `node-role.kubernetes.io/infra=true:NoSchedule`) if any worker should host infra workloads.
4. Post-bootstrap validation:
   - `kubectl get nodes -o wide` ensures 10 nodes Ready; control-plane nodes remain tainted.
   - `kubectl get pods -A | grep -E "cilium|core-dns|metrics-server"` shows all platform pods Running.
   - `kubectl run -it --rm test --image=registry.k8s.io/busybox:1.36 --restart=Never -- wget -qO- https://kubernetes.default.svc`.
   - CNI check: `kubectl -n kube-system exec ds/cilium-XXXXX -- cilium status`.
5. Conformance smoke tests:
   - Run `sonobuoy run --mode quick` (or equivalent suite).
   - Collect results: `sonobuoy retrieve` and store tarball in artifact bucket with timestamp and change ticket reference.

## Outputs and evidence
- Store bootstrap log bundle (journalctl from each node, RKE2 install logs).
- Record versions: RKE2 version, CNI version, kube-proxy mode, container runtime info.
- Update CMDB/ticket with node inventory and validation results.

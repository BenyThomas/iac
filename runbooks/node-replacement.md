# Runbook: Node Replacement (Epic O1)

Use this runbook to replace failed or out-of-compliance nodes (control-plane or worker) without violating quorum or service SLOs.

## Preconditions
- Current cluster health green (`kubectl get nodes`, ingress/CNI sanity checks).
- Latest etcd snapshot available and copied off-cluster; Velero backups current for platform namespaces.
- Replacement host is racked, patched, and has network/storage access matching the retired node. Cloud-init/Ansible inventory updated with the new host metadata.

## O1.1 — Evacuate the failing node
1. Identify node role and taints:
   ```bash
   kubectl get nodes -o wide
   kubectl describe node <node>
   ```
2. Cordon and drain to evacuate workloads (for control-plane nodes, expect API blips during pod rescheduling):
   ```bash
   kubectl cordon <node>
   kubectl drain <node> --ignore-daemonsets --delete-emptydir-data --grace-period=60
   ```
3. For a control-plane node, stop services to avoid flapping membership:
   ```bash
   sudo systemctl stop rke2-server || sudo systemctl stop rke2-agent
   ```
4. Remove the node object once workloads have moved:
   ```bash
   kubectl delete node <node>
   ```
   Note the pod reschedules and any evictions in the change ticket.

## O1.2 — Prepare and join the replacement host
1. Apply OS baseline (CIS hardening, NTP, container runtime deps) and copy the environment-specific RKE2 config (channel/version, token, server URL, taints/labels) to `/etc/rancher/rke2/config.yaml`.
2. Install RKE2 packages/binaries and enable the service:
   ```bash
   sudo systemctl enable --now rke2-server   # control-plane
   # or
   sudo systemctl enable --now rke2-agent    # worker
   ```
3. Verify registration and CNI readiness:
   ```bash
   kubectl get nodes -o wide
   kubectl -n kube-system logs ds/cilium-<suffix> -c cilium --tail=20
   ```
4. Re-apply intended labels/taints (for specialized workloads):
   ```bash
   kubectl label node <node> node-role.kubernetes.io/infra=true
   kubectl taint node <node> node-role.kubernetes.io/infra=true:NoSchedule
   ```

## O1.3 — Post-replacement validation
- Control-plane quorum: `kubectl get --raw /readyz?verbose | grep etcd` returns `ok` on each server.
- Workload validation: smoke test ingress endpoints, confirm DaemonSets (CNI, logging, monitoring) are Ready on the new node, and that PDBs were respected during drain.
- Clean up old host: remove from monitoring/CMDB and ensure secrets/SSH keys are rotated if the hardware is decommissioned.
- Evidence to attach to the ticket: drain timestamps, `kubectl get nodes -o wide`, RKE2 version/labels on the new node, and screenshots or CLI logs of smoke tests.

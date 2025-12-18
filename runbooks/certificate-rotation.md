# Runbook: Certificate Rotation (Epic O1)

Purpose: rotate Kubernetes API/kubelet/ingress certificates on RKE2 clusters before expiration while keeping control-plane quorum.

## Preconditions
- Maintenance window approved; cluster health green (`kubectl get nodes`, `/readyz`).
- Backup: most recent etcd snapshot saved off-cluster; kubeconfigs for admins exported.
- Confirm expiry window:
  ```bash
  sudo rke2 certificate expiration --days 90
  ```
  Use this to choose the rotation order (oldest first).

## O1.4 — Control-plane certificate rotation (one node at a time)
1. On the target control-plane node, rotate certificates:
   ```bash
   sudo rke2 certificate rotate --service kube-apiserver --service kube-controller-manager \
     --service kube-scheduler --service kubelet --service etcd
   ```
2. Restart services to pick up the new certs:
   ```bash
   sudo systemctl restart rke2-server
   ```
3. Wait for the node to return to `Ready` and `/readyz` to show all `ok` before moving to the next control-plane node:
   ```bash
   kubectl get nodes -o wide
   kubectl get --raw /readyz?verbose | grep -v ok
   ```
4. Repeat steps 1–3 for remaining control-plane nodes sequentially.

## O1.5 — Worker/ingress node rotation
1. Drain the worker if it hosts stateful or ingress workloads:
   ```bash
   kubectl drain <node> --ignore-daemonsets --delete-emptydir-data --grace-period=60
   ```
2. Rotate kubelet/ingress certs and restart the agent:
   ```bash
   sudo rke2 certificate rotate --service kubelet
   sudo systemctl restart rke2-agent
   ```
3. Uncordon and verify DaemonSets reschedule:
   ```bash
   kubectl uncordon <node>
   kubectl get pods -A -o wide | grep <node>
   ```

## O1.6 — Post-rotation validation
- Verify kubeconfigs still authenticate (`kubectl cluster-info` from an admin laptop) and that API audit logs show new certificate serials.
- Spot-check Harbor ingress and admission webhooks (Kyverno) to ensure TLS handshakes succeed.
- Capture evidence in the change ticket: `rke2 certificate expiration` after rotation, `kubectl get nodes -owide`, and a sample `kubectl logs` or webhook call proving TLS validity.

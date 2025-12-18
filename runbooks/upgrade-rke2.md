# Runbook: RKE2 Upgrade Procedure (with rollback)

Purpose: controlled, auditable upgrade of RKE2 clusters with rollback steps and staged validation.

## Preconditions
- Change ticket approved with maintenance window and risk rating.
- Current cluster health green: `kubectl get cs` (if enabled), `kubectl get nodes`, CNI status, ingress sanity check.
- Backup:
  - `rke2 etcd-snapshot save` taken and copied off-cluster.
  - Application backups validated for critical namespaces.
- Target version chosen and validated in non-prod (see Staging/Validation).
- Airgap artifacts (RKE2 binary, images, helm charts) mirrored if required.

## Staging/Validation (non-prod first)
1. Upgrade a non-prod environment (dev/uat) using the same steps below.
2. Run smoke tests:
   - `sonobuoy run --mode quick` and capture results.
   - Business probes (ingress test URL, sample API transaction).
3. Document findings in the change ticket: version numbers, duration, issues encountered.

## Control-plane upgrade (prod)
1. Announce start; cordon+drain control-plane #1: `kubectl drain <cp1> --ignore-daemonsets --delete-emptydir-data`.
2. Update RKE2 channel/version on the node:
   - Set `/etc/rancher/rke2/config.yaml` `channel:` or `version: vX.Y.Z`.
   - `systemctl restart rke2-server`.
3. Wait for node Ready and workloads rescheduled:
   - `kubectl get nodes` shows `Ready`.
   - `kubectl get pods -A -o wide | grep <cp1>` no pending/evicted critical pods.
4. Repeat for control-plane #2 then #3 one at a time.
5. Post-CP checks:
   - `kubectl get pods -n kube-system` all Ready.
   - `kubectl -n kube-system exec ds/cilium-XXXXX -- cilium status` OK.
   - API failover: stop kubelet on any control-plane briefly to confirm VIP/LB still responds.

## Worker upgrade
1. Process workers in batches (e.g., 2 at a time):
   - `kubectl drain <worker> --ignore-daemonsets --delete-emptydir-data --grace-period=30`.
   - Update `config.yaml` version and restart `rke2-agent`.
   - `kubectl uncordon <worker>` after Ready.
2. Repeat until all 7 workers upgraded.
3. Verify daemonsets (CNI, logging) rolled successfully on all nodes.

## Rollback plan
- If control-plane upgrade fails before quorum is lost:
  - Reinstall prior RKE2 version on the impacted node, restore `/etc/rancher/rke2/config.yaml`, restart service.
- If etcd health degrades:
  - Stop RKE2 on the broken node, restore from latest etcd snapshot: `rke2 server --cluster-reset --etcd-snapshot-name <snapshot>`, then restart normally.
- If cluster-wide regression:
  - Roll back all nodes to prior version (server then agent) using preserved binaries/config.
  - Restore etcd snapshot if data corruption suspected.

## Post-upgrade validation
- `kubectl get nodes -o wide` shows all nodes Ready with expected version.
- `kubectl get cs` (if enabled) and API `/readyz` return healthy.
- `sonobuoy run --mode quick` and capture results tarball.
- Business smoke tests and ingress checks pass.
- Update change ticket with:
  - Start/end times, versions (from `rke2 --version` and `kubectl version --short`).
  - Any deviations/incident records.
  - Links to validation artifacts and snapshots.

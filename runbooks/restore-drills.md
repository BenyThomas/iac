# Runbook: Restore Drills (Epic O1)

Exercise restores regularly to validate backups, DR objectives, and evidence collection.

## Preconditions
- Non-production or isolated restore target available (separate cluster or dedicated namespaces).
- Current Velero schedules and etcd snapshots confirmed; Harbor backup artifacts present.
- Change ticket open with scope (control-plane restore, workload restore, registry restore) and success criteria.

## O1.10 — Control-plane (etcd) restore rehearsal
1. Select a recent snapshot: `sudo rke2 etcd-snapshot ls` and pick the latest healthy entry.
2. On a single control-plane node in the drill environment, run a restore:
   ```bash
   sudo systemctl stop rke2-server
   sudo rke2 server --cluster-reset --cluster-reset-restore-path /var/lib/rancher/rke2/server/db/snapshots/<snapshot>
   sudo rm /var/lib/rancher/rke2/server/db/cluster-reset
   sudo systemctl start rke2-server
   ```
3. Confirm the control-plane returns (`kubectl get nodes`, `/readyz`) and that other control-plane nodes rejoin.

## O1.11 — Application/namespace restore (Velero)
1. Create an isolated namespace for the drill:
   ```bash
   NS=dr-restore-$(date +%Y%m%d)
   kubectl create namespace $NS
   ```
2. Restore from the platform-critical schedule without overwriting production:
   ```bash
   velero restore create --from-schedule platform-critical-nightly \
     --namespace-mappings platform-services:$NS
   ```
3. Validate:
   - Pods become Ready; PVCs bound.
   - Harbor UI loads in the restored namespace; perform a sample push/pull against the restored endpoint if exposed internally.
4. Clean up the drill namespace after evidence is captured.

## O1.12 — Harbor-specific restore test
1. Mount the latest `backup.sh` output into a scratch pod or node.
2. Restore DB and registry export into a temporary namespace (`harbor-restore-<date>`), reusing the Harbor values file with DR overrides (ingress host, storage class).
3. Validate authentication, project list, artifact signatures, and Trivy scan triggers.

## O1.13 — Evidence and close-out
- Record backup identifiers, restore commands, timestamps, and validation screenshots/logs in the change ticket.
- Note RPO/RTO achieved versus target, gaps discovered, and remediation owners.
- Update runbooks or automation to address any failures before marking the drill complete.

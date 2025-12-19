# Runbook: Backup, Restore, and DR (Epic N)

Use this runbook to prove automated backups and disaster recovery for control plane data, platform workloads, and the Harbor registry.

## Preconditions
- Access to the cluster kubeconfig and Velero CLI configured for the cluster.
- Access to the S3/object storage bucket used by RKE2 and Velero.
- Host with `rke2` binaries (for etcd restore) and Harbor admin credentials.

## N1 — etcd snapshots (schedule + restore test)
1. Validate automation is running:
   ```bash
   sudo rke2 etcd-snapshot ls
   journalctl -u rke2-server | grep "etcd-snapshot"
   ```
   Expect snapshots every 6 hours with uploads to S3.
2. Restore test (quarterly, in maintenance window):
   - Copy the desired snapshot from S3 to `/var/lib/rancher/rke2/server/db/snapshots/` on one control-plane node.
   - Stop services: `sudo systemctl stop rke2-server && sudo systemctl stop rke2-agent || true` on the chosen node.
   - Run reset/restore:
     ```bash
     sudo rke2 server --cluster-reset --cluster-reset-restore-path /var/lib/rancher/rke2/server/db/snapshots/<snapshot>
     ```
   - Remove the `cluster-reset` file at `/var/lib/rancher/rke2/server/db/cluster-reset` and restart: `sudo systemctl start rke2-server`.
   - Wait for the API to return and for other control-plane nodes to rejoin; confirm `kubectl get nodes` healthy.
   - Record evidence (snapshot name, timestamps, `kubectl get nodes`, etc.) in the change ticket.

## N2 — Velero backups for PVCs and platform databases
1. Confirm schedules are present and healthy:
   ```bash
   velero schedule get
   velero backup get
   ```
   The `platform-critical-nightly` and `cluster-resources-daily` schedules should show recent successful backups.
2. Restore drill (quarterly):
   - Choose the latest `platform-critical-nightly` backup.
   - Restore into an isolated namespace to avoid clobbering production data:
     ```bash
     kubectl create namespace dr-restore-$(date +%Y%m%d)
     velero restore create --from-schedule platform-critical-nightly \
       --namespace-mappings platform-services:dr-restore-$(date +%Y%m%d)
     ```
   - Validate: pods start, PVCs bound, Harbor UI loads, and sample pushes/pulls succeed in the restore namespace.
   - Clean up the test namespace after validation and note results in the ticket.

## N3 — Harbor replication and DR verification
1. Ensure the DR registry entry and replication policy exist (see `platform/harbor/README.md`).
2. Trigger a manual replication and validate:
   ```bash
   curl -u admin:$HARBOR_ADMIN_PASSWORD -X POST \
     https://registry.tcbbank.co.tz/api/v2.0/replication/executions \
     -H 'Content-Type: application/json' \
     -d '{"policy_id":<prod-to-dr-policy-id>}'
   ```
3. Confirm execution success via UI or `GET /api/v2.0/replication/executions` and pull the replicated image from the DR endpoint. Verify cosign signature if enabled.
4. Document RPO/RTO achieved, any failed artifacts, and remediation actions. Repeat monthly or after Harbor upgrades.

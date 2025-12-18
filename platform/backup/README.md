# Backup, Restore, and DR (Epic N)

Guidance for automated etcd snapshots, persistent volume/database backups, and Harbor registry replication. Use these defaults to satisfy Epic N while keeping evidence for quarterly DR exercises.

## N1 — Automate etcd backups
- RKE2 exposes an etcd snapshot service. Drop the provided config at `/etc/rancher/rke2/config.yaml.d/20-etcd-backup.yaml` on **every control-plane node** and restart `rke2-server`:
  ```bash
  sudo cp platform/backup/etcd-snapshot-config.yaml /etc/rancher/rke2/config.yaml.d/20-etcd-backup.yaml
  sudo systemctl restart rke2-server
  ```
- Default schedule: every 6 hours, keep 28 snapshots, push to the S3 bucket/folder defined in the config. Adjust the `etcd-s3-*` values per environment.
- Verification: `sudo rke2 etcd-snapshot ls` and `journalctl -u rke2-server | grep "etcd-snapshot"` must show recurring uploads.
- Restoration (documented in `runbooks/backup-disaster-recovery.md`): download the desired snapshot from the bucket, place it under `/var/lib/rancher/rke2/server/db/snapshots/`, then run `rke2 server --cluster-reset --cluster-reset-restore-path <snapshot>` on a single control-plane node.

## N2 — Back up persistent volumes and platform databases
- Deploy Velero with your cloud/provider plugin (vSphere, S3-compatible) and Restic/FS backups enabled. Ensure a `BackupStorageLocation` named `default` and a `VolumeSnapshotLocation` are ready before scheduling backups.
- Apply the curated schedules for critical namespaces (Harbor, GitOps/Argo CD, Jenkins) and cluster resources:
  ```bash
  kubectl apply -f platform/backup/velero-schedules.yaml
  velero schedule get
  ```
- The schedules capture PVC snapshots and a filesystem backup fallback. Harbor also exports DB + registry artifacts via its `backup.sh` script; mount `/backup` or provide S3 creds in the pod environment.
- Quarterly: execute restore drills in an isolated cluster/namespace using the active schedules, and record evidence in the change ticket. Steps are in `runbooks/backup-disaster-recovery.md`.

## N3 — Registry replication / DR readiness
- Configure Harbor replication from the primary to the DR registry (or secondary Harbor project). Create a remote registry entry, then post the policy in `platform/harbor/replication-policy.dr.json` with the correct destination registry ID and namespace.
- Cron-triggered replication runs every 4 hours by default; adjust the `trigger.trigger_settings.cron` value if you need different RPO.
- Validate DR readiness monthly by triggering a manual replication, pulling the replicated artifact from the DR endpoint, and running a signed image verification. Procedures are in `runbooks/harbor-supply-chain.md` and `runbooks/backup-disaster-recovery.md`.

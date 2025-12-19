# Runbook: Harbor Registry Recovery (Epic O1/O2)

Recover Harbor when the primary registry is degraded or unavailable. Use alongside `platform/harbor/README.md` for DR configuration specifics.

## Preconditions
- Incident declared; change/incident ticket open with timestamps and impact.
- Access to the latest Harbor DB dump + registry export (from Velero/backup.sh), S3 bucket/registry storage, and the Harbor encryption/secret keys.
- DR site or fresh namespace/cluster available for restore, with DNS/ingress ready for the registry hostname.

## O1.7 — Stabilize and gather backups
1. Freeze writes: disable project webhooks and pause CI pushes; optionally scale ingress to zero to stop new sessions.
2. Confirm backup currency:
   ```bash
   velero backup get | grep harbor
   ls /backup/harbor-*.tgz  # output from backup.sh
   ```
3. Export the Harbor encryption key and robot account secrets from the latest backup artifacts.

## O1.8 — Rebuild Harbor services
1. Provision replacement volumes/namespace matching the original storage classes.
2. Restore Harbor database:
   ```bash
   kubectl -n platform-services exec -it deploy/harbor-database -- sh -c \
     "psql -U postgres -d registry < /backup/harbor-db.sql"
   ```
3. Restore registry artifacts to object storage or attached volume:
   ```bash
   tar -xzvf /backup/harbor-registry.tgz -C /var/lib/registry
   ```
   (For S3 backends, re-point the bucket and re-sync via `registryctl`.)
4. Restore Harbor encryption/secret key to the expected path (`/data/secretkey` or the Kubernetes secret) and restart Harbor pods:
   ```bash
   kubectl -n platform-services rollout restart deploy/harbor-core
   kubectl -n platform-services rollout status deploy/harbor-core
   ```

## O1.9 — Validate and re-open registry
- Login test: `docker login registry.tcbbank.co.tz` using an admin or robot credential.
- Projects and tags: `curl -u admin:$HARBOR_ADMIN_PASSWORD https://registry.tcbbank.co.tz/api/v2.0/projects` lists expected projects; spot-check a critical artifact and its signature with `cosign verify`.
- Replication: trigger a manual execution to DR and confirm success.
- Scans: start a vulnerability scan on a prod artifact and ensure thresholds are enforced.
- Once validation passes, unfreeze CI pushes and re-enable ingress replicas.

## Evidence
- Attach backup identifiers (Velero backup name, DB dump filename, registry export timestamp), `kubectl get pods -n platform-services`, replication execution output, and cosign verification logs to the incident record.

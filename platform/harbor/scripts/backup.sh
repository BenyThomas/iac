#!/usr/bin/env bash
set -euo pipefail

# Harbor backup helper. Mount /backup to persistent storage or rely on an S3-compatible bucket.
# Required env vars: HARBOR_DB_HOST, HARBOR_DB_USER, HARBOR_DB_PASSWORD, HARBOR_STORAGE_PATH (/data/harbor/registry),
# optional: S3_BUCKET_URL (s3://bucket/prefix) and AWS_* creds for uploading the archive.

: "${HARBOR_DB_HOST:?missing db host}"
: "${HARBOR_DB_USER:?missing db user}"
: "${HARBOR_DB_PASSWORD:?missing db password}"
: "${HARBOR_STORAGE_PATH:?missing registry path (e.g., /storage/registry)}"

BACKUP_ROOT=${BACKUP_ROOT:-/backup/harbor}
TIMESTAMP=$(date -Iseconds)
RUN_DIR="${BACKUP_ROOT}/${TIMESTAMP}"
mkdir -p "$RUN_DIR"

export PGPASSWORD="$HARBOR_DB_PASSWORD"
pg_dump -h "$HARBOR_DB_HOST" -U "$HARBOR_DB_USER" -Fc harbor > "${RUN_DIR}/harbor-db.dump"

# Export registry blobs and charts (if chartmuseum is enabled) into a tarball.
tar -czf "${RUN_DIR}/registry-data.tgz" -C "$HARBOR_STORAGE_PATH" .

# Capture project + robot metadata (avoids storing secrets, focuses on config).
curl -sS -u admin:"${HARBOR_ADMIN_PASSWORD:-}" "https://${HARBOR_HOST:-harbor.registry.example.com}/api/v2.0/projects" > "${RUN_DIR}/projects.json" || true
curl -sS -u admin:"${HARBOR_ADMIN_PASSWORD:-}" "https://${HARBOR_HOST:-harbor.registry.example.com}/api/v2.0/robots" > "${RUN_DIR}/robots.json" || true

ARCHIVE="${RUN_DIR}.tgz"
tar -czf "$ARCHIVE" -C "$BACKUP_ROOT" "$TIMESTAMP"

if [[ -n "${S3_BUCKET_URL:-}" ]]; then
  echo "Uploading backup to ${S3_BUCKET_URL}/${TIMESTAMP}.tgz"
  aws s3 cp "$ARCHIVE" "${S3_BUCKET_URL}/${TIMESTAMP}.tgz"
fi

echo "Harbor backup completed: ${ARCHIVE}"

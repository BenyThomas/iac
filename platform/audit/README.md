# Kubernetes API audit logging

Enable and ship Kubernetes API audit logs to provide traceability for platform and application activity.

## Enable audit logging on RKE2 servers
1. Copy the audit policy to every control-plane node:
   ```bash
   sudo mkdir -p /etc/rancher/rke2
   sudo cp platform/audit/rke2-audit-policy.yaml /etc/rancher/rke2/audit-policy.yaml
   ```
2. Append the following to `/etc/rancher/rke2/config.yaml` (or merge with existing values):
   ```yaml
   kube-apiserver-arg:
     - "audit-log-path=/var/lib/rancher/rke2/server/logs/audit.log"
     - "audit-log-maxage=30"
     - "audit-log-maxsize=200"
     - "audit-log-maxbackup=10"
     - "audit-policy-file=/etc/rancher/rke2/audit-policy.yaml"
   ```
3. Restart the API server: `sudo systemctl restart rke2-server` (rolling across control-plane nodes). Validate new audit lines are appended to `/var/lib/rancher/rke2/server/logs/audit.log`.

## Ship audit logs to the central stack / SIEM
Apply the dedicated Fluent Bit DaemonSet to read the host audit log and forward to Loki (and optionally a SIEM endpoint):
```bash
kubectl create ns logging --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f platform/audit/fluent-bit-audit.yaml
```

- Mounts the host audit log with a read-only `hostPath`.
- Sends logs to the in-cluster Loki gateway (`loki-gateway.logging.svc:80`).
- Add an additional `[OUTPUT]` block in the ConfigMap to mirror to your SIEM or object storage archive.

Retention aligns with the Loki 30-day policy; adjust in the logging stack if longer retention is required by compliance.

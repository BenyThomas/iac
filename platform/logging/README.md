# Centralized logging (Loki + Fluent Bit)

Centralize platform, workload, ingress, and node logs into Loki. The provided Helm values deploy Loki in single-binary mode with 30-day retention and a Fluent Bit DaemonSet that enriches Kubernetes metadata before shipping logs.

## Deploy Loki
```bash
kubectl create ns logging
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm upgrade --install loki grafana/loki -n logging -f platform/logging/loki-values.yaml
```

## Deploy Fluent Bit shipper
```bash
helm upgrade --install fluent-bit fluent/fluent-bit -n logging -f platform/logging/fluent-bit-values.yaml
```

- Collects container stdout/stderr via `/var/log/containers/*.log`.
- Captures node systemd/journal entries for kubelet, container runtime, and network components.
- Ships ingress controller logs (match `ingress-nginx`), platform namespaces, and application logs with labels for namespace, app, and environment.
- Output is the Loki gateway service (`loki-gateway.logging.svc:80`) secured inside the cluster.

## Retention
Retention is set to **30 days** via the Loki limits/table manager in `loki-values.yaml`. Adjust `limits_config.retention_period` and `table_manager.retention_period` to shorten or extend retention. For SIEM mirroring, add an additional Fluent Bit output to your SIEM endpoint without removing the Loki output.

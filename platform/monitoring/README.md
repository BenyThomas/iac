# Monitoring stack (Prometheus + Grafana)

Kube Prometheus Stack provides cluster and application metrics with curated dashboards and alerting. Deploy it into the `monitoring` namespace with the included values file.

## Deploy / upgrade
1. Bootstrap namespace: `kubectl create ns monitoring` (idempotent).
2. Install or upgrade via Helm:
   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo update
   helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
     -n monitoring -f platform/monitoring/kube-prometheus-stack-values.yaml
   ```
3. Expose Grafana (port-forward or ingress). The values file enables the dashboards sidecar so ConfigMaps/Secrets labeled `grafana_dashboard` are automatically loaded. Store the admin password in a secret referenced by `grafana.admin.existingSecret`.

## Coverage
- Prometheus scrapes node, kubelet, cAdvisor, and pod-level metrics via ServiceMonitor/PodMonitor discovery.
- Grafana ships with Kubernetes, node, API server, and etcd dashboards. Drop additional dashboards as ConfigMaps with `grafana_dashboard` labels.
- Alertmanager routes platform alerts; wire SMTP/Slack/PagerDuty by populating the referenced secret.

## Alerting rules
Additional alert rules defined in `kube-prometheus-stack-values.yaml`:
- **NodeHighCpuUtilization** — CPU >90% for 15m with namespace/node labels.
- **NodeMemoryPressure** — available memory <10% for 15m.
- **NodeDiskPressure** — filesystem free <10% for 15m (non-ephemeral filesystems).
- **KubeApiErrorRate** — API server 5xx error ratio >1% for 10m.
- **NodeFilesystemReadOnly** — detects nodes remounting filesystems read-only.

Tune thresholds or add notification routing using the Helm values file; all alerts are namespaced under the `monitoring` namespace for RBAC scoping.

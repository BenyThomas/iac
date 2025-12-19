# cert-manager deployment and issuer standards

## Purpose
Provide automated certificate issuance and renewal for platform services using cert-manager with enterprise PKI (preferred) or an internal CA.

## Deployment
- Namespace: `cert-manager` managed via GitOps (Argo CD).
- Install via Helm chart with CRDs enabled (`--set installCRDs=true`).
- API server admission/metrics:
  - Enable `prometheus.enabled=true` and `prometheus.servicemonitor.enabled=true` for monitoring.
  - Expose webhook via the ingress controller only if required.
- Pod security: run in restricted PSP/PSS namespaces; set resource requests/limits.

Example Helm values snippet (overlay per environment):
```yaml
installCRDs: true
prometheus:
  enabled: true
  servicemonitor:
    enabled: true
webhook:
  securityContext:
    runAsNonRoot: true
    fsGroup: 1001
``` 

## Issuer configuration
- Preferred: **enterprise PKI** intermediate. Provision a secret `tls-issuer-root` that includes the signer key/cert (or references a Vault/PKI backend if using external issuers).
- Alternative: **internal CA** with short validity, distributed to nodes/clients.
- Create ClusterIssuers (cluster scope) plus optional namespace-scoped Issuers for app teams.

Example ClusterIssuer (CA):
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: platform-ca
spec:
  ca:
    secretName: tls-issuer-root
```

Example ClusterIssuer (enterprise PKI via ACME/HTTP01):
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: enterprise-pki
spec:
  acme:
    email: platform-pki@tcbbank.co.tz
    server: https://pki.tcbbank.co.tz/acme/directory
    privateKeySecretRef:
      name: enterprise-pki-acme-key
    solvers:
    - http01:
        ingress:
          class: nginx
```

Issuer governance
- Owners: Platform (operational), Security (approval for new issuers and signer rotation).
- Changes to issuers and trust bundles require PR + change record and distribution to nodes/CI agents.

## Certificates and renewal
- Standard annotations:
  - `cert-manager.io/renew-before: 720h` (30 days) for platform endpoints.
  - `cert-manager.io/common-name` set to the service DNS record.
- Certificates for ingress hosts (apps, Argo CD, Grafana, Harbor) are requested via HTTP01 or DNS01 depending on DNS provider.
- Certificates must include SANs for VIP, DNS, and node hostnames where applicable (API/ingress).
- Auto-renewal: cert-manager renews certificates before `renewBefore`; ensure webhook/controller pods are highly available (3 replicas in prod).

## Monitoring and alerting
- Export metrics via ServiceMonitor; key metrics:
  - `certmanager_certificate_expiration_timestamp_seconds`
  - `certmanager_certificate_ready_status`
  - `certmanager_http01solver_challenges` / `certmanager_dns01solver_challenges`
- Alerts (Prometheus rule examples):
  - **CertExpiry14d**: expiration < 14 days.
  - **CertNotReady**: `ready_status` != 1 for >15m.
- Dashboards: include cert expiry table in Grafana; Argo CD app health alerts on cert-manager releases.

## Validation and runbook steps
1. Deploy cert-manager release and wait for controller/webhook to be Ready.
2. Apply ClusterIssuers (`platform-ca`, `enterprise-pki`), secrets, and validate `Ready=True`.
3. Issue a test Certificate (`test.platform.local`) and confirm secret material is populated.
4. Verify renewal by setting `renewBefore: 2160h` and using `kubectl cert-manager renew <name>` in non-prod.
5. Monitor metrics/alerts for renewals and failed challenges; document outages in postmortems.

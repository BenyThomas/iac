# Compliance Evidence Collection (Epic O2)

Collect and store artifacts that prove controls are enforced across RBAC, policies, supply chain, and backups. Save outputs to the change/assessment ticket and to a secured evidence bucket with timestamps.

## O2.1 — RBAC mappings
- Export cluster roles/bindings and map them to OIDC groups (Keycloak):
  ```bash
  kubectl get clusterrole,clusterrolebinding -o yaml > evidence/rbac-cluster-$(date +%F).yaml
  kubectl get rolebinding -A -o yaml > evidence/rbac-namespaced-$(date +%F).yaml
  ```
- Run spot checks against expected groups (see `platform/identity/access-controls.md`):
  ```bash
  kubectl auth can-i --as-group=developers-<team> get secrets -n other-team
  kubectl auth can-i --as-group=security-auditors get pods -A
  ```
- Store command output and the mapping table used for the review.

## O2.2 — Policy sets (admission, network, and supply chain)
- Admission/PSA/Kyverno:
  ```bash
  kubectl get validatingwebhookconfigurations,mutatingwebhookconfigurations -o wide
  kubectl get clusterpolicy,policy -A -o yaml > evidence/kyverno-policies-$(date +%F).yaml
  ```
- Network isolation:
  ```bash
  kubectl get networkpolicy -A -o yaml > evidence/network-policies-$(date +%F).yaml
  ```
- Supply chain gates (signed images, allowed registries): capture the applied manifests from `policies/supply-chain/` and admission logs showing enforcement events. Include the Kyverno verifyImages policy output (`kubectl get clusterpolicy verify-signed-images -o yaml`).

## O2.3 — Scan reports
- Harbor/Trivy reports:
  ```bash
  curl -u admin:$HARBOR_ADMIN_PASSWORD \
    https://harbor.registry.example.com/api/v2.0/projects/<proj>/repositories/<repo>/artifacts/<tag>/additions/vulnerabilities \
    -o evidence/trivy-<proj>-<repo>-<tag>-$(date +%F).json
  ```
- Pipeline evidence: attach the latest Jenkins/CI job artifacts that show the scanning stage results and thresholds applied.
- Document any CVE allowlists/exceptions and their expiry dates.

## O2.4 — Signed-image enforcement
- Cosign verification sample for a prod artifact:
  ```bash
  cosign verify --key cosign.pub harbor.registry.example.com/prod/<app>:<tag>
  ```
- Admission proof: `kubectl get events -A | grep -i verifyImages` or Kyverno reports showing unsigned image denials.
- Capture the Cosign public key ConfigMap and Kyverno verifyImages policy from GitOps manifests as immutable evidence.

## O2.5 — Patch and version records
- Capture OS and RKE2 versions from each node:
  ```bash
  kubectl get nodes -o wide
  kubectl get node -o json | jq -r '.items[] | "\(.metadata.name),\(.status.nodeInfo.kubeletVersion),\(.status.nodeInfo.osImage)"' > evidence/node-versions-$(date +%F).csv
  ```
- Attach change tickets for recent upgrades (see `runbooks/upgrade-rke2.md`) and patch baselines (e.g., `dnf history`/`apt history` logs from configuration management).

## O2.6 — Backup logs and restore proof
- Etcd snapshots:
  ```bash
  sudo rke2 etcd-snapshot ls > evidence/etcd-snapshots-$(date +%F).txt
  ```
- Velero backups and restores:
  ```bash
  velero backup get > evidence/velero-backups-$(date +%F).txt
  velero restore get > evidence/velero-restores-$(date +%F).txt
  ```
- Harbor DR evidence: replication execution output, registry export filenames, and successful restore drill logs (see `runbooks/restore-drills.md`).
- Store screenshots/logs from the most recent restore drill validation.

## Storage and retention
- Commit evidence to an immutable bucket or artifact repository with foldering by date and change/incident ID.
- Keep at least one full audit set per quarter plus per-change submissions; follow enterprise retention policies for security logs and audit artifacts.

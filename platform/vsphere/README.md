# vSphere integration (CPI + CSI)

This folder provides Kubernetes manifests (kustomize-ready) for the vSphere Cloud Provider Interface (CPI/CCM) and the vSphere CSI driver, along with storage classes for the fast and standard tiers referenced in the target architecture.

## Structure
- `cpi/`: vSphere Cloud Provider Interface deployment (out-of-tree cloud controller manager) with least-privileged credentials, cluster ID, and providerID support.
- `csi/`: vSphere CSI driver controller + node plugins and storage classes for `vsphere-fast` and `vsphere-standard`.

## Usage
1. Update credentials and environment specifics:
   - `cpi/cloud-config-secret.yaml` and `csi/csi-secret.yaml` require vCenter FQDN, TLS thumbprint (if not using a trusted CA), datacenter list, cluster ID, and least-privileged service accounts with only the permissions required for CPI/CSI.
   - Align `storagePolicyName` values in `csi/storage-classes.yaml` with the vSAN/vSphere policies mapped to the fast/standard tiers.
2. Apply each stack with kustomize (kubectl >=1.21 supports `--enable-kyaml=false --enable-helm` if using helm charts; these manifests do not require Helm):
   - `kubectl apply -k platform/vsphere/cpi`
   - `kubectl apply -k platform/vsphere/csi`
3. Validate:
   - Nodes should show provider IDs (`kubectl get nodes -o wide` -> `providerID` should start with `vsphere://`).
   - CSI pods in `vmware-system-csi` should be Ready and StorageClasses should be visible (`kubectl get sc`).
   - Provision/expand/snapshot PVCs using the runbook in `runbooks/vsphere-cpi-csi.md`.

## Security
- Credentials are stored only in Kubernetes Secrets; avoid committing real values.
- Use vCenter roles that grant CPI only inventory read + tag lookup and CSI only datastore and storage policy operations needed for provisioning. Document the effective permissions in your ops runbook.

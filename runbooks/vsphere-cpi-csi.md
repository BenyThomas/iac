# vSphere CPI/CSI installation and validation

## Prerequisites
- RKE2/Kubernetes control-plane reachable with cluster-admin context.
- vCenter least-privileged accounts created:
  - `svc-vsphere-cpi`: inventory read, node lookup, tag/cluster read, required for providerID updates.
  - `svc-vsphere-csi`: datastore access scoped to the storage policies used for provisioning/snapshots/expansion.
- vCenter TLS thumbprint recorded if using a private CA.

## Install CPI (cloud controller manager)
1. Edit `platform/vsphere/cpi/cloud-config-secret.yaml` with the vCenter FQDN, datacenter(s), thumbprint, and credentials. Set `cluster-id` to the Kubernetes cluster ID (unique per cluster).
2. Deploy:
   ```bash
   kubectl apply -k platform/vsphere/cpi
   ```
3. Verification:
   - Ensure the deployment is available:
     ```bash
     kubectl -n kube-system get deploy vsphere-cloud-controller-manager
     ```
   - Confirm nodes have provider IDs and cloud labels:
     ```bash
     kubectl get nodes -o custom-columns=NAME:.metadata.name,PROVIDER_ID:.spec.providerID
     ```
   - Check controller logs for successful vCenter auth and node reconciliation:
     ```bash
     kubectl -n kube-system logs deploy/vsphere-cloud-controller-manager
     ```

## Install CSI driver
1. Edit `platform/vsphere/csi/csi-secret.yaml` for vCenter details and the shared `cluster-id`. Align `storage-classes.yaml` with the intended storage policies (`vsphere-fast`, `vsphere-standard`).
2. Deploy:
   ```bash
   kubectl apply -k platform/vsphere/csi
   ```
3. Verification:
   - Pods healthy:
     ```bash
     kubectl -n vmware-system-csi get pods
     ```
   - StorageClasses present:
     ```bash
     kubectl get storageclass
     ```
   - CSI driver registered:
     ```bash
     kubectl get csidrivers csi.vsphere.vmware.com -o yaml | head
     ```

## Functional validation
1. **Provisioning**
   ```bash
   cat <<'EOF' | kubectl apply -f -
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: vsphere-fast-smoke
   spec:
     accessModes: ["ReadWriteOnce"]
     resources:
       requests:
         storage: 10Gi
     storageClassName: vsphere-fast
   EOF
   kubectl wait --for=condition=Bound pvc/vsphere-fast-smoke --timeout=5m
   ```
2. **Expansion**
   ```bash
   kubectl patch pvc vsphere-fast-smoke -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'
   kubectl wait --for=jsonpath='{.status.capacity.storage}'=20Gi pvc/vsphere-fast-smoke --timeout=5m
   ```
3. **Snapshot (if snapshot-controller installed)**
   ```bash
   cat <<'EOF' | kubectl apply -f -
   apiVersion: snapshot.storage.k8s.io/v1
   kind: VolumeSnapshotClass
   metadata:
     name: vsphere-fast-snapclass
   driver: csi.vsphere.vmware.com
   deletionPolicy: Delete
   parameters:
     storagePolicyName: vsan-perf
   ---
   apiVersion: snapshot.storage.k8s.io/v1
   kind: VolumeSnapshot
   metadata:
     name: vsphere-fast-snapshot
   spec:
     volumeSnapshotClassName: vsphere-fast-snapclass
     source:
       persistentVolumeClaimName: vsphere-fast-smoke
   EOF
   kubectl wait --for=condition=Ready volumesnapshot/vsphere-fast-snapshot --timeout=5m
   ```
4. **Cleanup**
   ```bash
   kubectl delete pvc vsphere-fast-smoke
   kubectl delete volumesnapshot vsphere-fast-snapshot volumesnapshotclass vsphere-fast-snapclass
   ```

## Storage policy mapping
- `vsphere-fast` → `storagePolicyName: vsan-perf` (vSAN/vVol policy tuned for performance)
- `vsphere-standard` → `storagePolicyName: vsan-default` (general-purpose policy)

Document any environment-specific policy IDs, datastore restrictions, or allowed folders in this runbook before promotion to production.

# Identity and access controls

## Keycloak (SSO) integration
- Configure the API server with OIDC settings (RKE2 `kube-apiserver-arg`):
  - `--oidc-issuer-url=https://idp.tcbbank.co.tz/realms/platform`
  - `--oidc-client-id=kubernetes`
  - `--oidc-username-claim=email` and `--oidc-groups-claim=groups`
  - `--oidc-ca-file=/etc/rancher/rke2/oidc-ca.pem` (enterprise PKI trust).
- Identity mapping:
  - Create Keycloak groups that map 1:1 with Kubernetes ClusterRoles/RoleBindings: `platform-admins`, `security-auditors`, `namespace-admins-<team>`, `developers-<team>`, `readers-<team>`.
  - Use `Group` or `GroupBinding` (Kyverno/Gatekeeper) policies to restrict who can bind cluster-admin.
- Admin access: no shared admin accounts. Use individual SSO logins with group-based elevation.
- Break-glass access:
  - Keep a disabled-by-default local admin kubeconfig (stored in secrets management), tied to a dated, auditable account.
  - Two approvals required to enable; rotate credentials immediately after use and capture kubectl audit logs.
  - Nightly job asserts break-glass account is disabled; alert if enabled longer than 1 hour.

## Standard RBAC roles
Roles are cluster-scoped definitions bound to namespaces per team. Aggregated ClusterRoles should be installed via GitOps and reviewed by Security.

| Role | Permissions | Binding scope |
|---|---|---|
| `platform-admin` | `cluster-admin` equivalent; manage cluster add-ons, nodes, storage, CRDs. Not for app teams. | Cluster-wide and platform namespaces only. |
| `security-auditor` | Read-only for all resources; can list/watch Secrets, audit logs, validating/mutating webhooks. No write. | Cluster-wide. |
| `namespace-admin` | Full control in assigned namespaces (including RBAC RoleBindings, NetworkPolicies, PVCs). Cannot edit cluster-scoped objects. | Per team namespace set. |
| `developer` | Create/update Deployments, Services, Ingresses, ConfigMaps/Secrets (opaque), Jobs; cannot change RBAC or NetworkPolicies. | Per team namespaces. |
| `read-only` | Get/list/watch all namespaced resources; no write. | Per team namespaces. |

Implementation checklist
- Create ClusterRoles for the above (use aggregation labels for consistency).
- Create Namespace-scoped RoleBindings targeting OIDC groups (`namespace-admins-<team>`, etc.).
- Protect platform namespaces: only `platform-admin` and `security-auditor` have access; app roles excluded.

## Verification of namespace isolation
- For each namespace, run `kubectl auth can-i --as-group=developers-<team> get secrets -n other-team` (expect **no**) and `--as-group=developers-<team> create deployment -n <team>` (expect **yes**).
- Validate network isolation by confirming default-deny NetworkPolicy exists and only intended ingress/egress is allowed.
- Audit API server logs for denied/allowed requests per group weekly; capture evidence in access review.
- Argo CD AppProjects should scope repositories/namespaces per team to prevent cross-namespace writes.

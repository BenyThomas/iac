# Argo CD bootstrap

GitOps entrypoint for the platform. Apply this kustomization to install Argo CD with SSO/RBAC and to seed the platform app-of-apps.

## What gets installed
- Argo CD v2.11.x from the official manifests (pinned tag).
- OIDC SSO (placeholder values) wired into `argocd-cm` and `argocd-secret`.
- Opinionated RBAC policies that map SSO groups to platform roles.
- An `AppProject` + app-of-apps that manages the platform component Applications.

## Prerequisites
- A DNS entry for the Argo CD server (update `argocd-cm.url`).
- OIDC client credentials stored in `argocd-secret` (`oidc.okta.clientId|clientSecret`).
- Kubectl access to the target cluster.

## Bootstrap steps
1. Update the Git repo URL in `platform-apps.yaml` to point at this repository (HTTPS or SSH).
2. Replace the OIDC placeholders in `sso-rbac.yaml` and ensure the matching keys exist in `argocd-secret` (SOPS/SealedSecrets recommended for real secrets).
3. Apply Argo CD + the bootstrap objects:
   ```bash
   kubectl apply -k platform/argocd/bootstrap
   ```
4. Log in via SSO; Argo CD will automatically create the platform Applications from the app-of-apps.

## SSO and RBAC
- SSO is configured with OIDC scopes for email/profile/groups.
- Default access is read-only (`policy.default: role:readonly`).
- Platform admins and platform readers are mapped to identity provider groups via RBAC policies in `argocd-rbac-cm`.

## App-of-apps
- `platform-apps` Application points to `platform/argocd/platform-apps` in this repo.
- Child Applications manage core platform components (networking, PKI, identity, Harbor) and create their namespaces if missing.

## Promotion and rollback
- Environment overlays live under `clusters/<env>/` and are promoted via Git PRs with required approvals.
- Rollbacks are handled by `git revert` followed by an Argo CD sync (see `runbooks/environment-promotion.md`).

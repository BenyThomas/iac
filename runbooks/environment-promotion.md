# Environment promotion (dev → uat → prod)

GitOps flow for moving changes across environments with approvals and reversible rollbacks.

## Promotion prerequisites
- Change is merged into `main` and applied to `clusters/dev/`.
- CI green (unit/integration) and dev smoke test complete.
- Any required security/vuln attestations are present in Harbor.

## Promotion steps
1. **Open a PR targeting the next environment folder** (`clusters/uat/` or `clusters/prod/`) with the version/tag change.
2. **Approvals required**
   - Dev → UAT: Platform approver + Service owner for the workload.
   - UAT → Prod: Platform approver + Service owner + Security (for prod or policy changes).
3. **Merge after approvals**. Argo CD will detect the Git change and sync according to policy.
4. **Verify**
   ```bash
   # Replace <env> with dev|uat|prod
   argocd app get platform-apps --refresh
   argocd app get <app-name> -o json | jq '.status'
   kubectl --context <env> get deploy,sts,ingress -A
   ```

## Rollback procedure
1. `git revert <sha>` for the promoting commit in the affected environment folder.
2. Push the revert to the branch and merge (same approval rules apply).
3. Trigger/confirm Argo CD sync:
   ```bash
   argocd app sync platform-apps
   argocd app sync <app-name>
   ```
4. Validate the deployment state matches the previous known-good release.

## Notes
- No direct kubectl edits on clusters; drift detection must stay enabled.
- Promotion history is fully auditable in Git (PRs + commit history).

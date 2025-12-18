# Branch Strategy and PR Approvals

## Branch model
- `main`: protected, always deployable baseline.
- Feature branches → PR into `main`.

## Environment overlays in Git
- `clusters/dev/`
- `clusters/uat/`
- `clusters/prod/`

Promotion is a PR updating manifests/tags/digests in the target env folder. Dev → UAT requires Platform + service owner approval; UAT → Prod adds Security approval.

## Required approvals
- Changes in `clusters/prod/` or `policies/`: Platform + Security approvals required (in addition to service owner).
- Changes in `terraform/`: Platform (+ Infra if separate).
- All PRs require CI checks to pass.

## Rollback standard
- Rollbacks are done with `git revert` against the environment folder commit followed by an Argo CD sync.
- No direct kubectl edits; Git + Argo remains the single source of truth.

## No manual drift
Direct changes on clusters are prohibited; Argo CD drift detection remains enabled.

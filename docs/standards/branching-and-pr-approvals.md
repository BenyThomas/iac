# Branch Strategy and PR Approvals

## Branch model
- `main`: protected, always deployable baseline.
- Feature branches → PR into `main`.

## Environment overlays in Git
- `clusters/dev/`
- `clusters/uat/`
- `clusters/prod/`

Promotion is a PR updating manifests/tags/digests in the target env folder.

## Required approvals
- Changes in `clusters/prod/` or `policies/`: Platform + Security approvals required.
- Changes in `terraform/`: Platform (+ Infra if separate).
- All PRs require CI checks to pass.

## No manual drift
Direct changes on clusters are prohibited; Argo CD drift detection remains enabled.

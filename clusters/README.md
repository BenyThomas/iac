# Clusters

Environment overlays consumed by Argo CD. Each folder holds manifests and values specific to that environment.

## Layout
- `clusters/dev/` — default landing zone for new changes.
- `clusters/uat/` — gated by Platform + service owner approval.
- `clusters/prod/` — gated by Platform + service owner + Security approval.

## Usage
- Promotion is performed by creating PRs that change tags/digests or configuration in the target environment folder.
- Argo CD watches these folders; merging a PR triggers sync (automated for platform apps, manual sync allowed for prod if desired).
- Roll back by reverting the commit that changed the environment folder and syncing Argo CD.

# RKE2 Upgrade Runbook (Placeholder)
- Preconditions: etcd snapshot OK, change window approved.
- Sequence: upgrade control-plane one-by-one, then workers in batches.
- Validation: node readiness, API health, CNI health, ingress tests.

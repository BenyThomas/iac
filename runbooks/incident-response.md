# Runbook: Platform Incident Response (Epic O1)

Guide for responding to platform-impacting incidents (API outages, registry compromise, CNI failures) with clear triage, containment, and recovery steps.

## Preconditions
- Pager/alert received with initial symptoms; on-call and comms channels engaged.
- Change/incident ticket opened with unique ID; note current cluster version and environment.

## O1.14 — Triage and classification
1. Identify impact and severity: API availability, tenant workloads, registry operations, or networking.
2. Gather fast signals (read-only):
   ```bash
   kubectl get --raw /readyz
   kubectl get pods -A --field-selector=status.phase!=Running
   kubectl -n kube-system logs ds/cilium-<suffix> -c cilium --tail=50
   ```
3. Confirm recent changes/deploys and decide if rollback is required (see upgrade/node replacement runbooks for procedures).

## O1.15 — Containment
- For suspected compromise or runaway workload:
  - Isolate namespaces with a temporary default-deny NetworkPolicy and pause Argo CD sync.
  - Cordon/drain affected nodes; stop `rke2-server`/`rke2-agent` on compromised hosts.
- For registry issues, freeze pushes and follow `runbooks/registry-recovery.md`.
- For control-plane instability, reduce blast radius by processing one control-plane node at a time and avoiding concurrent rotations/upgrades.

## O1.16 — Eradication and recovery
1. Execute the relevant remediation play (upgrade rollback, node replacement, certificate rotation, registry recovery).
2. Validate recovery with smoke tests:
   - `kubectl get nodes -o wide` and `/readyz` show healthy control-plane.
   - Ingress checks succeed; critical workloads Ready; Harbor login + pull succeeds.
3. Remove temporary containment controls (NetworkPolicies, cordons) after validation.

## O1.17 — Evidence and follow-up
- Preserve logs: API server audit logs, Harbor logs, and `kubectl describe` outputs for impacted resources.
- Capture timestamps for detection, containment, recovery, and validation; attach to the incident ticket.
- File follow-up actions (postmortem, automation fixes, test coverage) and link to the corresponding runbook updates needed.

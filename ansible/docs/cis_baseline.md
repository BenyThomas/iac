# CIS alignment overview

This repository ships opinionated defaults that map to common CIS Linux Server and Kubernetes recommendations. The table below shows where automation exists and where follow-up is needed.

| Area | Implementation | Notes |
| ---- | -------------- | ----- |
| Swap disabled | `roles/os_baseline` disables swap and comments fstab entries | Required for kubelet scheduling stability. |
| Kernel modules and sysctls | `roles/os_baseline` loads `overlay` and `br_netfilter` and sets bridge forwarding sysctls | Matches Kubernetes prerequisites. |
| Time synchronization | `roles/os_baseline` installs and starts chrony/chronyd | Required for log integrity. |
| Container runtime | `roles/os_baseline` installs containerd and configures systemd cgroups | Uses registry.k8s.io pause image. |
| SSH hardening | `roles/os_baseline` enforces root-login disablement, password auth disablement, and idle timeouts | Extend with banners or MFA as needed. |
| Audit logging | `roles/security_hardening` deploys auditd rules for identity, network, and session events | Consider expanding with privileged command monitoring. |
| Service/port restrictions | `roles/security_hardening` disables legacy services and configures a deny-by-default firewall | Allowlist ports through `security_hardening_allowed_ports`. |
| Patch management | `roles/security_hardening` enables unattended-upgrades or dnf-automatic | Tune cadence in inventory vars. |

## Operational checks

- Run `ansible-playbook -i <inventory> playbooks/baseline.yml --check` to validate changes.
- Verify audit rules with `auditctl -l` on a target host.
- Confirm firewall drop policy with `firewall-cmd --get-default-zone` (RHEL) or `ufw status` (Debian).

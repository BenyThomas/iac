# Ansible automation

This directory contains Ansible roles and playbooks that configure the operating system baseline and security hardening for Kubernetes nodes.

## Layout

- `playbooks/` — Example playbooks that apply the provided roles.
- `roles/os_baseline/` — Configures OS prerequisites: swap handling, kernel modules/sysctls, time sync, containerd, SSH hardening, and admin users.
- `roles/security_hardening/` — Enables audit logging, restricts legacy services, configures a minimal firewall baseline, and sets up automated patch management.
- `docs/` — Reference notes for CIS alignment and patching strategy.

## Running the baseline

```bash
ansible-playbook -i <inventory> playbooks/baseline.yml
```

Provide the inventory that targets the nodes you want to prepare. You can override role defaults through inventory or `--extra-vars`.

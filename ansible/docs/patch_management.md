# Patch management approach

The `security_hardening` role enables automated updates so that baseline nodes receive security fixes promptly.

## Debian/Ubuntu

- Installs `unattended-upgrades` when `security_hardening_enable_patch_automation` is `true` (default).
- Writes `/etc/apt/apt.conf.d/51auto-upgrades` to enable daily package list refresh and unattended upgrades.
- Starts and enables the `unattended-upgrades` service.

## RHEL/CentOS/Rocky/Alma

- Installs `dnf-automatic` when `security_hardening_enable_patch_automation` is `true`.
- Ensures the `dnf-automatic.timer` systemd unit is enabled and running for scheduled updates.

## Operational guidance

- Override `security_hardening_patch_package` if your distribution uses an alternate update agent.
- Set `security_hardening_enable_patch_automation: false` in inventory for environments that use external patch orchestration.
- Review update results regularly (e.g., `/var/log/unattended-upgrades` or `journalctl -u dnf-automatic*`).

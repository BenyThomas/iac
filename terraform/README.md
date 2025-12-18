# Terraform

# Epic B1 — vSphere Networking via Terraform
Generated: 2025-12-18

This package includes:
- Terraform module to create vSphere **Distributed Port Groups** (VLAN-backed) for MGMT, NODES, STORAGE, INGRESS/DMZ.
- Firewall/ports matrix to implement in NSX-T or perimeter firewalls/ACLs.
- Optional NSX-T Terraform stub (placeholders).

Assumptions:
- vSphere with a Distributed Virtual Switch (DVS).

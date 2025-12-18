provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = var.allow_unverified_ssl
}

data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_distributed_virtual_switch" "dvs" {
  name          = var.dvs_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

locals {
  env_offset = lookup(var.env_vlan_offsets, var.env, 0)

  port_groups = {
    mgmt = {
      enabled     = var.enable_networks.mgmt
      name        = "PG-${var.site}-${var.env}-K8S-MGMT"
      vlan_id     = var.base_vlans.mgmt + local.env_offset
      description = "${var.description_prefix} - MGMT network"
    }
    nodes = {
      enabled     = var.enable_networks.nodes
      name        = "PG-${var.site}-${var.env}-K8S-NODES"
      vlan_id     = var.base_vlans.nodes + local.env_offset
      description = "${var.description_prefix} - Node network"
    }
    storage = {
      enabled     = var.enable_networks.storage
      name        = "PG-${var.site}-${var.env}-K8S-STORAGE"
      vlan_id     = var.base_vlans.storage + local.env_offset
      description = "${var.description_prefix} - Storage network"
    }
    ingress_dmz = {
      enabled     = var.enable_networks.ingress_dmz
      name        = "PG-${var.site}-${var.env}-K8S-INGRESS-DMZ"
      vlan_id     = var.base_vlans.ingress_dmz + local.env_offset
      description = "${var.description_prefix} - Ingress/DMZ network"
    }
  }

  enabled_port_groups = { for k, v in local.port_groups : k => v if v.enabled }
}

resource "vsphere_distributed_port_group" "pg" {
  for_each = local.enabled_port_groups

  name                            = each.value.name
  description                     = each.value.description
  distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.dvs.id
  vlan_id                         = each.value.vlan_id

  allow_promiscuous = var.security_policy.allow_promiscuous
  forged_transmits  = var.security_policy.forged_transmits
  mac_changes       = var.security_policy.mac_changes
}

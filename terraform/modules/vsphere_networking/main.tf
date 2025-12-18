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

resource "vsphere_distributed_port_group" "pg" {
  for_each = var.networks

  name                            = each.value.name
  description                     = each.value.description
  distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.dvs.id

  vlan_id = each.value.vlan_id

  # Enterprise default: keep FALSE unless explicitly required
  allow_promiscuous = try(each.value.allow_promiscuous, false)
  forged_transmits  = try(each.value.forged_transmits, false)
  mac_changes       = try(each.value.mac_changes, false)

  dynamic "inbound_shaping" {
    for_each = (try(each.value.average_bandwidth, null) != null) ? [1] : []
    content {
      enabled           = true
      average_bandwidth = each.value.average_bandwidth
      peak_bandwidth    = try(each.value.peak_bandwidth, each.value.average_bandwidth)
      burst_size        = try(each.value.burst_size, 1024)
    }
  }

  dynamic "outbound_shaping" {
    for_each = (try(each.value.average_bandwidth, null) != null) ? [1] : []
    content {
      enabled           = true
      average_bandwidth = each.value.average_bandwidth
      peak_bandwidth    = try(each.value.peak_bandwidth, each.value.average_bandwidth)
      burst_size        = try(each.value.burst_size, 1024)
    }
  }
}

output "port_groups" {
  value = {
    for k, v in vsphere_distributed_port_group.pg : k => {
      id      = v.id
      name    = v.name
      vlan_id = v.vlan_id
    }
  }
}

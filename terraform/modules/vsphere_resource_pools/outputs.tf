output "resource_pool_ids" { value = { for k, v in data.vsphere_resource_pool.rp : k => v.id } }

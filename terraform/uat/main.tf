module "networking" {
  source = "../../modules/vsphere_networking_opinionated"

  vsphere_server       = var.vsphere_server
  vsphere_user         = var.vsphere_user
  vsphere_password     = var.vsphere_password
  allow_unverified_ssl = var.allow_unverified_ssl

  datacenter = var.datacenter
  dvs_name   = var.dvs_name

  site = var.site
  env  = "uat"
}

module "tags" {
  source = "../../modules/vsphere_tags"

  vsphere_server       = var.vsphere_server
  vsphere_user         = var.vsphere_user
  vsphere_password     = var.vsphere_password
  allow_unverified_ssl = var.allow_unverified_ssl

  datacenter   = var.datacenter
  site         = var.site
  env          = "uat"
  cluster_name = var.cluster_name
  additional_tags = var.additional_tags
}

module "resource_pools" {
  source = "../../modules/vsphere_resource_pools"

  vsphere_server       = var.vsphere_server
  vsphere_user         = var.vsphere_user
  vsphere_password     = var.vsphere_password
  allow_unverified_ssl = var.allow_unverified_ssl

  datacenter     = var.datacenter
  resource_pools = var.resource_pools
}

output "port_groups" { value = module.networking.port_groups }
output "tag_ids" { value = module.tags.tag_ids }
output "resource_pool_ids" { value = module.resource_pools.resource_pool_ids }

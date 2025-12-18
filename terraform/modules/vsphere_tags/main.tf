provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = var.allow_unverified_ssl
}

data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

locals {
  base_tags = [
    "site-${var.site}",
    "env-${var.env}",
    "cluster-${var.cluster_name}",
    "role-control-plane",
    "role-worker",
    "tier-platform",
    "tier-app"
  ]
  tags_to_create = distinct(concat(local.base_tags, var.additional_tags))
}

resource "vsphere_tag_category" "cat" {
  count            = var.create ? 1 : 0
  name             = var.tag_category_name
  description      = "Kubernetes platform tagging category"
  cardinality      = "MULTIPLE"
  associable_types = ["VirtualMachine"]
}

resource "vsphere_tag" "tag" {
  for_each = var.create ? toset(local.tags_to_create) : toset([])
  name        = each.value
  category_id = vsphere_tag_category.cat[0].id
  description = "Managed by Terraform"
}

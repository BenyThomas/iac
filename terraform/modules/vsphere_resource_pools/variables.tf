variable "vsphere_server" { type = string }
variable "vsphere_user" { type = string }
variable "vsphere_password" { type = string sensitive = true }
variable "allow_unverified_ssl" { type = bool default = false }

variable "datacenter" { type = string }
variable "resource_pools" { type = map(string) default = {} }

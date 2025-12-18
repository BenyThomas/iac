variable "vsphere_server" { type = string }
variable "vsphere_user" { type = string }
variable "vsphere_password" { type = string sensitive = true }
variable "allow_unverified_ssl" { type = bool default = false }

variable "datacenter" { type = string }

variable "tag_category_name" { type = string default = "k8s" }
variable "site" { type = string }
variable "env"  { type = string }
variable "cluster_name" { type = string }

variable "additional_tags" { type = list(string) default = [] }
variable "create" { type = bool default = true }

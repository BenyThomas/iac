variable "vsphere_server" { type = string }
variable "vsphere_user" { type = string }
variable "vsphere_password" { type = string sensitive = true }
variable "allow_unverified_ssl" { type = bool default = false }

variable "datacenter" { type = string }
variable "dvs_name" { type = string }

variable "site" { type = string }
variable "env" {
  type = string
  validation {
    condition     = contains(["dev","uat","prod"], var.env)
    error_message = "env must be one of dev, uat, prod"
  }
}

variable "base_vlans" {
  type = object({
    mgmt        = number
    nodes       = number
    storage     = number
    ingress_dmz = number
  })
  default = {
    mgmt        = 110
    nodes       = 120
    storage     = 130
    ingress_dmz = 140
  }
}

variable "env_vlan_offsets" {
  type = object({
    dev  = number
    uat  = number
    prod = number
  })
  default = {
    dev  = 0
    uat  = 100
    prod = 200
  }
}

variable "enable_networks" {
  type = object({
    mgmt        = bool
    nodes       = bool
    storage     = bool
    ingress_dmz = bool
  })
  default = {
    mgmt        = true
    nodes       = true
    storage     = true
    ingress_dmz = true
  }
}

variable "security_policy" {
  type = object({
    allow_promiscuous = bool
    forged_transmits  = bool
    mac_changes       = bool
  })
  default = {
    allow_promiscuous = false
    forged_transmits  = false
    mac_changes       = false
  }
}

variable "description_prefix" {
  type    = string
  default = "Kubernetes Platform"
}

variable "vsphere_server" { type = string }
variable "vsphere_user" { type = string }
variable "vsphere_password" { type = string sensitive = true }
variable "allow_unverified_ssl" { type = bool default = false }

variable "datacenter" { type = string }
variable "dvs_name" { type = string }

variable "networks" {
  description = "Map of distributed port groups to create."
  type = map(object({
    name        = string
    vlan_id     = number
    description = optional(string, "")
    allow_promiscuous = optional(bool, false)
    forged_transmits  = optional(bool, false)
    mac_changes       = optional(bool, false)
    average_bandwidth = optional(number)
    peak_bandwidth    = optional(number)
    burst_size        = optional(number)
  }))
}

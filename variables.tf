////////////////////////
// Variables
////////////////////////

variable "tags" {
  type = map(string)

  default = {}
}

variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
}

variable "subnet" {
  type = object({
    name                 = string
    resource_group_name  = string
    virtual_network_name = string
  })
}

variable "nsg_enabled" {
  description = "Enable Network Security Group."

  type    = bool
  default = true
}

variable "nsg_rules" {
  description = "Custom Network Security Rules."

  type = list(object({
    name     = string
    priority = number

    description = optional(string)
    direction   = optional(string, "Inbound")
    access      = optional(string, "Allow")
    protocol    = optional(string, "Tcp")

    destination_address_prefix                 = optional(string)
    destination_address_prefixes               = optional(list(string))
    destination_port_range                     = optional(string)
    destination_port_ranges                    = optional(list(string))
    destination_application_security_group_ids = optional(list(string))

    source_address_prefix                 = optional(string)
    source_address_prefixes               = optional(list(string))
    source_port_range                     = optional(string)
    source_port_ranges                    = optional(list(string))
    source_application_security_group_ids = optional(list(string))
  }))

  default = []
}

variable "public_ip_name" {
  type    = string
  default = "bastion-pip"
}

variable "public_ip_sku" {
  type    = string
  default = "Standard"

  validation {
    condition     = contains(["Standard"], var.public_ip_sku)
    error_message = "Requires 'Standard' SKU."
  }
}

variable "public_ip_allocation_method" {
  type    = string
  default = "Static"

  validation {
    condition     = contains(["Static"], var.public_ip_allocation_method)
    error_message = "Requires 'Static' allocation."
  }
}

variable "bastion_prefix" {
  type    = string
  default = "bastion"
}

variable "bastion_sku" {
  type    = string
  default = "Basic"

  validation {
    condition     = contains(["Basic", "Standard"], var.bastion_sku)
    error_message = "Unsupported SKU. Requires 'Basic' or 'Standard'"
  }
}

variable "copy_paste_enabled" {
  type    = bool
  default = true
}

variable "bastion_sku_standard" {
  description = "Optional settings. Requires 'Standard' SKU, if changed."

  type = object({
    file_copy_enabled      = optional(bool, false)
    ip_connect_enabled     = optional(bool, false)
    scale_units            = optional(number, 2)
    shareable_link_enabled = optional(bool, false)
    tunneling_enabled      = optional(bool, false)
  })

  default = {}
}

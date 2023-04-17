////////////////////////
// Configuration
////////////////////////

locals {
  rg_prefix   = "tf-bastion"
  rg_location = "northeurope"

  vnet_name          = "x-virtual-network"
  vnet_address_space = ["192.168.168.0/24"]
}

////////////////////////
// Resources
////////////////////////

resource "random_id" "X" {
  keepers = {
    prefix = local.rg_prefix
  }

  byte_length = 3
}

resource "azurerm_resource_group" "MAIN" {
  name     = join("-", [random_id.X.keepers.prefix, "VNet", random_id.X.hex])
  location = local.rg_location
}

resource "azurerm_virtual_network" "MAIN" {
  name                = local.vnet_name
  address_space       = local.vnet_address_space
  resource_group_name = azurerm_resource_group.MAIN.name
  location            = azurerm_resource_group.MAIN.location
}

////////////////////////
// Example Internal VM
////////////////////////
// TODO

////////////////////////
// Module | Bastion
////////////////////////

module "AZURE_BASTION_HOST" {
  source = "../../../terraform-azurerm-bastion"

  // Overrides
  subnet = {
    vnet_index = 0
    newbits    = 3
    netnum     = 0
  }

  nsg_enabled = false

  // External Resource References
  resource_group  = azurerm_resource_group.MAIN
  virtual_network = azurerm_virtual_network.MAIN
}

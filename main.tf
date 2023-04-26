////////////////////////
// Sources
////////////////////////

data "azurerm_resource_group" "MAIN" {
  name = var.resource_group.name
}

data "azurerm_virtual_network" "MAIN" {
  name                = var.subnet.virtual_network_name
  resource_group_name = var.subnet.resource_group_name
}

data "azurerm_subnet" "MAIN" {
  name                 = var.subnet.name
  resource_group_name  = var.subnet.resource_group_name
  virtual_network_name = var.subnet.virtual_network_name
}

////////////////////////
// Network
////////////////////////

resource "azurerm_public_ip" "MAIN" {
  name                = var.public_ip_name
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku
  tags                = var.tags
  location            = data.azurerm_virtual_network.MAIN.location
  resource_group_name = data.azurerm_virtual_network.MAIN.resource_group_name
}

////////////////////////
// Network Security
////////////////////////

resource "azurerm_network_security_group" "MAIN" {
  count = var.nsg_enabled ? 1 : 0

  name                = format("%s-nsg", data.azurerm_subnet.MAIN.name)
  tags                = var.tags
  location            = data.azurerm_virtual_network.MAIN.location
  resource_group_name = data.azurerm_virtual_network.MAIN.resource_group_name
}

resource "azurerm_network_security_rule" "EXTRA" {
  for_each = {
    for rule in var.nsg_rules : join("-", [rule.direction, rule.priority]) => rule
    if var.nsg_enabled
  }

  name     = each.value["name"]
  priority = each.value["priority"]

  description = each.value["description"]
  direction   = each.value["direction"]
  access      = each.value["access"]
  protocol    = each.value["protocol"]

  destination_address_prefix                 = each.value["destination_address_prefix"]
  destination_address_prefixes               = each.value["destination_address_prefixes"]
  destination_port_range                     = each.value["destination_port_range"]
  destination_port_ranges                    = each.value["destination_port_ranges"]
  destination_application_security_group_ids = each.value["destination_application_security_group_ids"]

  source_address_prefix                 = each.value["source_address_prefix"]
  source_address_prefixes               = each.value["source_address_prefixes"]
  source_port_range                     = each.value["source_port_range"]
  source_port_ranges                    = each.value["source_port_ranges"]
  source_application_security_group_ids = each.value["source_application_security_group_ids"]

  network_security_group_name = one(azurerm_network_security_group.MAIN[*].name)
  resource_group_name         = data.azurerm_virtual_network.MAIN.resource_group_name
}

// See https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg
resource "azurerm_network_security_rule" "REQUIRED" {
  for_each = {
    for rule in [{
      name                       = "AllowHttpsInbound"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "Internet"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "443"
      }, {
      name                       = "AllowGatewayManagerInbound"
      priority                   = 130
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "GatewayManager"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "443"
      }, {
      name                       = "AllowAzureLoadbalancerInbound"
      priority                   = 140
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "AzureLoadBalancer"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "443"
      }, {
      name                       = "AllowBastionHostCommunication"
      priority                   = 150
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_address_prefix      = "AzureLoadBalancer"
      source_port_range          = "*"
      destination_address_prefix = "VirtualNetwork"
      destination_port_ranges    = ["8080", "5701"]
      }, {
      name                       = "AllowSshRdpOutbound"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "VirtualNetwork"
      destination_port_ranges    = ["22", "3389"]
      }, {
      name                       = "AllowAzureCloudOutbound"
      priority                   = 110
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "AzureCloud"
      destination_port_range     = "443"
      }, {
      name                       = "AllowBastionCommunication"
      priority                   = 120
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_address_prefix      = "VirtualNetwork"
      source_port_range          = "*"
      destination_address_prefix = "VirtualNetwork"
      destination_port_ranges    = ["8080", "5701"]
      }, {
      name                       = "AllowHttpOutbound"
      priority                   = 130
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_address_prefix      = "VirtualNetwork"
      source_port_range          = "*"
      destination_address_prefix = "Internet"
      destination_port_range     = "80"
    }] : join("-", [rule.direction, rule.priority]) => rule
    if var.nsg_enabled
  }

  name     = each.value["name"]
  priority = each.value["priority"]

  description = "Mandatory Azure Bastion rule. See 'https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg'"
  direction   = each.value["direction"]
  access      = each.value["access"]
  protocol    = each.value["protocol"]

  destination_address_prefix   = try(each.value["destination_address_prefix"], null)
  destination_address_prefixes = try(each.value["destination_address_prefixes"], null)
  destination_port_range       = try(each.value["destination_port_range"], null)
  destination_port_ranges      = try(each.value["destination_port_ranges"], null)

  source_address_prefix   = try(each.value["source_address_prefix"], null)
  source_address_prefixes = try(each.value["source_address_prefixes"], null)
  source_port_range       = try(each.value["source_port_range"], null)
  source_port_ranges      = try(each.value["source_port_ranges"], null)

  network_security_group_name = one(azurerm_network_security_group.MAIN[*].name)
  resource_group_name         = data.azurerm_virtual_network.MAIN.resource_group_name
}

////////////////////////
// Bastion
////////////////////////

resource "azurerm_bastion_host" "MAIN" {
  name                   = format("%s-%s", var.bastion_prefix, data.azurerm_virtual_network.MAIN.name)
  copy_paste_enabled     = var.copy_paste_enabled
  file_copy_enabled      = var.bastion_sku_standard.file_copy_enabled
  ip_connect_enabled     = var.bastion_sku_standard.ip_connect_enabled
  scale_units            = var.bastion_sku_standard.scale_units
  shareable_link_enabled = var.bastion_sku_standard.shareable_link_enabled
  tunneling_enabled      = var.bastion_sku_standard.tunneling_enabled

  ip_configuration {
    name                 = "bastion-ipcfg"
    subnet_id            = data.azurerm_subnet.MAIN.id
    public_ip_address_id = azurerm_public_ip.MAIN.id
  }

  tags                = var.tags
  location            = data.azurerm_resource_group.MAIN.location
  resource_group_name = data.azurerm_resource_group.MAIN.name
}

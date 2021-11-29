data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.resource_suffix}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  address_space       = [var.address_space]

  ddos_protection_plan {
    enable = true
    id     = azurerm_network_ddos_protection_plan.main.id
  }
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_virtual_network.main.resource_group_name
  address_prefixes     = [cidrsubnet(var.address_space, 8, 0)]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_virtual_network.main.resource_group_name
  address_prefixes     = [cidrsubnet(var.address_space, 8, 1)]
}

resource "azurerm_subnet" "service" {
  name                                           = "snet-${var.resource_suffix}-pe"
  virtual_network_name                           = azurerm_virtual_network.main.name
  resource_group_name                            = azurerm_virtual_network.main.resource_group_name
  address_prefixes                               = [cidrsubnet(var.address_space, 8, 2)]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "host" {
  name                 = "snet-${var.resource_suffix}-vm"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_virtual_network.main.resource_group_name
  address_prefixes     = [cidrsubnet(var.address_space, 8, 3)]
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = azurerm_subnet.bastion.id
  network_security_group_id = azurerm_network_security_group.bastion.id
}

resource "azurerm_network_ddos_protection_plan" "main" {
  name                = "ddos-${var.resource_suffix}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_public_ip_prefix" "main" {
  name                = "ippre-${var.resource_suffix}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  availability_zone   = "Zone-Redundant"
  ip_version          = "IPv4"
  prefix_length       = 31
}

resource "azurerm_network_security_group" "bastion" {
  name                = "nsg-${var.resource_suffix}-bas"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowInternetInbound"
    access                     = "Allow"
    priority                   = 100
    protocol                   = "Tcp"
    direction                  = "Inbound"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "443"
  }

  security_rule {
    name                       = "AllowControlPlaneInbound"
    access                     = "Allow"
    priority                   = 110
    protocol                   = "Tcp"
    direction                  = "Inbound"
    source_address_prefix      = "GatewayManager"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "443"
  }

  security_rule {
    name                       = "AllowHealthProbesInbound"
    access                     = "Allow"
    priority                   = 120
    protocol                   = "Tcp"
    direction                  = "Inbound"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_ranges    = ["8080", "5701"]
  }

  security_rule {
    name                       = "DenyAllInbound"
    access                     = "Deny"
    priority                   = 1000
    protocol                   = "*"
    direction                  = "Inbound"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }

  security_rule {
    name                       = "AllowRemoteOutbound"
    access                     = "Allow"
    priority                   = 100
    protocol                   = "Tcp"
    direction                  = "Outbound"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_ranges    = ["22", "3389"]
  }

  security_rule {
    name                       = "AllowCloudOutbound"
    access                     = "Allow"
    priority                   = 110
    protocol                   = "Tcp"
    direction                  = "Outbound"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "AzureCloud"
    destination_port_range     = "443"
  }

  security_rule {
    name                       = "AllowDataPlaneOutbound"
    access                     = "Allow"
    priority                   = 120
    protocol                   = "Tcp"
    direction                  = "Outbound"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_ranges    = ["8080", "5701"]
  }

  security_rule {
    name                       = "DenyAllOutbound"
    access                     = "Deny"
    priority                   = 130
    protocol                   = "*"
    direction                  = "Outbound"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_range     = "*"
  }
}

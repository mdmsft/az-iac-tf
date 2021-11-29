terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.86.0"
    }
  }

  backend "azurerm" {
    key = "hub"
  }
}

provider "azurerm" {
  features {}
}

locals {
  resource_suffix           = "${var.project}-${var.environment}-${var.location}-${var.instance}"
  private_dns_zone_registry = "privatelink.azurecr.io"
  private_dns_zone_cluster  = "privatelink.${var.location}.azmk8s.io"
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.resource_suffix}"
  location = var.location
  tags = {
    project     = var.project
    environment = var.environment
    instance    = var.instance
  }
}

module "monitor" {
  source              = "./monitor"
  resource_group_name = azurerm_resource_group.main.name
  resource_suffix     = local.resource_suffix
  depends_on = [
    azurerm_resource_group.main
  ]
}

module "network" {
  source              = "./network"
  resource_group_name = azurerm_resource_group.main.name
  resource_suffix     = local.resource_suffix
  address_space       = var.virtual_network_address_space
  depends_on = [
    azurerm_resource_group.main
  ]
}

module "dns" {
  source              = "./dns"
  resource_group_name = azurerm_resource_group.main.name
  resource_suffix     = local.resource_suffix
  virtual_network_id  = module.network.virtual_network_id
  for_each = toset([
    local.private_dns_zone_registry,
    local.private_dns_zone_cluster,
  ])
  zone_name = each.key
  depends_on = [
    azurerm_resource_group.main
  ]
}

module "bastion" {
  source                     = "./bastion"
  resource_group_name        = azurerm_resource_group.main.name
  resource_suffix            = local.resource_suffix
  subnet_id                  = module.network.bastion_subnet_id
  public_ip_prefix_id        = module.network.public_ip_prefix_id
  log_analytics_workspace_id = module.monitor.log_analytics_workspace_id
  depends_on = [
    azurerm_resource_group.main
  ]
}

module "firewall" {
  source                     = "./firewall"
  resource_group_name        = azurerm_resource_group.main.name
  resource_suffix            = local.resource_suffix
  subnet_id                  = module.network.firewall_subnet_id
  public_ip_prefix_id        = module.network.public_ip_prefix_id
  log_analytics_workspace_id = module.monitor.log_analytics_workspace_id
  depends_on = [
    azurerm_resource_group.main
  ]
}

module "registry" {
  source              = "./registry"
  resource_group_name = azurerm_resource_group.main.name
  resource_suffix     = local.resource_suffix
  subnet_id           = module.network.service_subnet_id
  private_dns_zone_id = module.dns[local.private_dns_zone_registry].id
  log_analytics_workspace_id = module.monitor.log_analytics_workspace_id
  depends_on = [
    azurerm_resource_group.main
  ]
}

module "jumpbox" {
  source              = "./jumpbox"
  resource_group_name = azurerm_resource_group.main.name
  resource_suffix     = local.resource_suffix
  subnet_id           = module.network.host_subnet_id
  admin_username      = var.jumpbox_admin_username
  admin_password      = var.jumpbox_admin_password
  depends_on = [
    azurerm_resource_group.main
  ]
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_private_dns_zone" "main" {
  name                = var.zone_name
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  name                  = azurerm_private_dns_zone.main.name
  virtual_network_id    = var.virtual_network_id
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  resource_group_name   = data.azurerm_resource_group.main.name
}

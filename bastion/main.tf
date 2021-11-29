data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_public_ip" "bastion" {
  name                = "pip-${var.resource_suffix}-bas"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  public_ip_prefix_id = var.public_ip_prefix_id
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "main" {
  name                = "bas-${var.resource_suffix}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                 = "default"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

resource "azurerm_monitor_diagnostic_setting" "bastion" {
  name                       = "default"
  log_analytics_workspace_id = var.log_analytics_workspace_id
  target_resource_id         = azurerm_bastion_host.main.id

  log {
    category = "BastionAuditLogs"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 7
    }
  }
}
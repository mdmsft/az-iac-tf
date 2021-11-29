data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_client_config" "main" {
}

locals {
  policies = {
    "Disable admin account"               = "dc921057-6b28-4fbe-9b83-f7bec05db6c2"
    "Disable unrestricted network access" = "d0793b48-0edc-4296-a390-4c75d1bdfd71"
    "Disable public network access"       = "0fdf0491-d080-4575-b627-ad0e843cba0f"
    "Disable non-premium SKUs"            = "bd560fc0-3c69-498a-ae9f-aa8eb7de0e13"
  }
}

resource "azurerm_container_registry" "main" {
  name                          = "cr${split("-", data.azurerm_client_config.main.subscription_id).0}"
  resource_group_name           = data.azurerm_resource_group.main.name
  location                      = data.azurerm_resource_group.main.location
  admin_enabled                 = false
  public_network_access_enabled = false
  zone_redundancy_enabled       = true
  sku                           = "Premium"
  anonymous_pull_enabled        = false
  network_rule_bypass_option    = "AzureServices"

  depends_on = [
    azurerm_resource_group_policy_assignment.registry
  ]
}

resource "azurerm_private_endpoint" "registry" {
  name                = "pe-${var.resource_suffix}-cr"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "cr-${var.resource_suffix}"
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

resource "azurerm_resource_group_policy_assignment" "registry" {
  for_each             = local.policies
  name                 = each.key
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/${each.value}"
  enforce              = true
  resource_group_id    = data.azurerm_resource_group.main.id
  parameters           = <<PARAMETERS
  {
    "effect": {
      "value": "Deny"
    }
  }
  PARAMETERS
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  name                       = "default"
  log_analytics_workspace_id = var.log_analytics_workspace_id
  target_resource_id         = azurerm_container_registry.main.id

  log {
    category = "ContainerRegistryRepositoryEvents"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 7
    }
  }

  log {
    category = "ContainerRegistryLoginEvents"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 7
    }
  }
}
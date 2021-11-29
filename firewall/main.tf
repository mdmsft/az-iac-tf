data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_public_ip" "firewall" {
  name                = "pip-${var.resource_suffix}-afw"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  public_ip_prefix_id = var.public_ip_prefix_id
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "main" {
  name                = "afw-${var.resource_suffix}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  firewall_policy_id  = azurerm_firewall_policy.base.id
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "default"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

resource "azurerm_firewall_policy" "base" {
  name                = "afwp-${var.resource_suffix}-base"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  dns {
    proxy_enabled = true
  }

  insights {
    enabled                            = true
    default_log_analytics_workspace_id = var.log_analytics_workspace_id
    retention_in_days                  = 7
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "base" {
  name               = "default"
  firewall_policy_id = azurerm_firewall_policy.base.id
  priority           = 100

  network_rule_collection {
    name     = "net"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "azure"
      source_addresses      = ["*"]
      destination_addresses = ["AzureActiveDirectory", "AzureMonitor", "MicrosoftContainerRegistry"]
      destination_ports     = ["443"]
      protocols             = ["TCP"]
    }

    rule {
      name              = "ntp"
      source_addresses  = ["*"]
      destination_fqdns = ["ntp.ubuntu.com"]
      destination_ports = ["123"]
      protocols         = ["UDP"]
    }
  }

  application_rule_collection {
    name     = "app"
    priority = 110
    action   = "Allow"

    rule {
      name              = "ubuntu"
      source_addresses  = ["*"]
      destination_fqdns = ["security.ubuntu.com", "azure.archive.ubuntu.com", "changelogs.ubuntu.com"]

      protocols {
        type = "Http"
        port = 80
      }
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  name                       = "default"
  log_analytics_workspace_id = var.log_analytics_workspace_id
  target_resource_id         = azurerm_firewall.main.id

  log {
    category = "AzureFirewallApplicationRule"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 7
    }
  }

  log {
    category = "AzureFirewallNetworkRule"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 7
    }
  }

  log {
    category = "AzureFirewallDnsProxy"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 7
    }
  }
}

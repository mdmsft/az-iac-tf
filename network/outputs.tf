output "ddos_protection_plan_id" {
  value = azurerm_network_ddos_protection_plan.main.id
}

output "virtual_network_name" {
  value = azurerm_virtual_network.main.name
}

output "firewall_subnet_id" {
  value = azurerm_subnet.firewall.id
}

output "bastion_subnet_id" {
  value = azurerm_subnet.bastion.id
}

output "service_subnet_id" {
  value = azurerm_subnet.service.id
}

output "host_subnet_id" {
  value = azurerm_subnet.host.id
}

output "public_ip_prefix_id" {
  value = azurerm_public_ip_prefix.main.id
}

output "virtual_network_id" {
  value = azurerm_virtual_network.main.id
}

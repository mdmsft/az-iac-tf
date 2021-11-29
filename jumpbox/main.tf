data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "template_file" "cloud_config" {
  template = filebase64("${path.module}/cloud-config.yaml")
}

resource "azurerm_network_interface" "jumpbox" {
  name                    = "nic-${var.resource_suffix}-jumpbox"
  resource_group_name     = data.azurerm_resource_group.main.name
  location                = data.azurerm_resource_group.main.location
  internal_dns_name_label = "jumpbox"

  ip_configuration {
    name                          = "primary"
    primary                       = true
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                            = "vm-${var.resource_suffix}-jumpbox"
  resource_group_name             = data.azurerm_resource_group.main.name
  location                        = data.azurerm_resource_group.main.location
  computer_name                   = "jumpbox"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  size                            = "Standard_B2s"
  custom_data                     = data.template_file.cloud_config.rendered

  network_interface_ids = [
    azurerm_network_interface.jumpbox.id
  ]

  os_disk {
    name                 = "osdisk-${var.resource_suffix}-jumpbox"
    disk_size_gb         = 32
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
}

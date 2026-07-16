# Intentionally vulnerable Terraform for Veracode IaC lab tests.
# Do not apply this configuration in any real environment.

resource "azurerm_resource_group" "lab" {
  name     = "rg-veracode-iac-lab"
  location = "eastus"
}

resource "azurerm_storage_account" "public_storage" {
  name                     = "veracodelabpublicsa"
  resource_group_name      = azurerm_resource_group.lab.name
  location                 = azurerm_resource_group.lab.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  allow_nested_items_to_be_public = true
  min_tls_version                 = "TLS1_0"
  shared_access_key_enabled       = true
  public_network_access_enabled   = true

  blob_properties {
    delete_retention_policy {
      days = 1
    }
  }
}

resource "azurerm_storage_container" "public_container" {
  name                  = "public-artifacts"
  storage_account_name  = azurerm_storage_account.public_storage.name
  container_access_type = "blob"
}

resource "azurerm_network_security_group" "open_admin_ports" {
  name                = "nsg-veracode-lab-open-admin"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  security_rule {
    name                       = "AllowSSHFromInternet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowRDPFromInternet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_linux_virtual_machine" "insecure_vm" {
  name                = "vm-veracode-lab-insecure"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = "TerraformLabPassword123!"

  disable_password_authentication = false

  network_interface_ids = [
    "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-veracode-iac-lab/providers/Microsoft.Network/networkInterfaces/nic-veracode-lab"
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

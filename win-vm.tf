terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.45.0"
    }
  }
}

# Declaring Variables
variable "storage_account_name" {
  type = string
  description = "Please enter the storage account name: "
  default = "tfstrgmalchiel001"
}

# Configure Provider
provider "azurerm" {
  # Configuration options
  subscription_id = var.subscription_id
  client_id = var.client_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id
  features {}
}

# Datablock: To get information about an existing resource on the Azure platform
data "azurerm_client_config" "current" {}

# Create Resource Group
resource "azurerm_resource_group" "application_grp" {
  name     = local.resource_group
  location = local.location
}

# Create a Virtual Network
resource "azurerm_virtual_network" "app_network" {
  name                = "app_network"
  location            = local.location
  resource_group_name = azurerm_resource_group.application_grp.name
  address_space       = ["10.0.0.0/16"]
}

# Creating Subnet
resource "azurerm_subnet" "subnetA" {
  name                 = "subnetA"
  resource_group_name  = local.resource_group
  virtual_network_name = azurerm_virtual_network.app_network.name
  address_prefixes     = ["10.0.1.0/24"]
  depends_on = [
    azurerm_virtual_network.app_network
  ]
}

# Creating a Public IP for the VM
resource "azurerm_public_ip" "app_public_ip" {
  name                = "app_public_ip"
  resource_group_name = local.resource_group
  location            = local.location
  allocation_method   = "Static"
  depends_on = [
    azurerm_resource_group.application_grp
  ]
}

#Creating a Network Security Group
resource "azurerm_network_security_group" "app_network_sg" {
  name                = "app-network-sg"
  location            = local.location
  resource_group_name = local.resource_group

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  depends_on = [
    azurerm_resource_group.application_grp
  ]
}

# Creating NSG Association
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id = azurerm_subnet.subnetA.id
  network_security_group_id = azurerm_network_security_group.app_network_sg.id
  depends_on = [
    azurerm_network_security_group.app_network_sg
  ]
}

# Creating an Azure Windows VM network interface
resource "azurerm_network_interface" "app_interface" {
  name                = "app_interface"
  location            = local.location
  resource_group_name = local.resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnetA.id
    public_ip_address_id          = azurerm_public_ip.app_public_ip.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    azurerm_virtual_network.app_network,
    azurerm_public_ip.app_public_ip,
    azurerm_subnet.subnetA
  ]
}

# Creating a Key Vault for Keys and Parameters
resource "azurerm_key_vault" "app_vault" {
  name                        = "app-vault55818168"
  location                    = local.location
  resource_group_name         = local.resource_group
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get", "Backup", "Delete", "List", "Purge", "Recover", "Restore", "Set",
    ]

    storage_permissions = [
      "Get",
    ]
  }
  depends_on = [
    azurerm_resource_group.application_grp
  ]
}

# Secret in the Key Value
resource "azurerm_key_vault_secret" "vmpassword" {
  name = "vmpassword"
  value = "Azure@123"
  key_vault_id = azurerm_key_vault.app_vault.id
  depends_on = [
    azurerm_key_vault.app_vault
  ]
}

# Creating VM
resource "azurerm_windows_virtual_machine" "app-windows-vm" {
  name                = "app-windows-vm"
  resource_group_name = local.resource_group
  location            = local.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  admin_password      = azurerm_key_vault_secret.vmpassword.value
  availability_set_id = azurerm_availability_set.app_set.id
  network_interface_ids = [
    azurerm_network_interface.app_interface.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.app_interface,
    azurerm_availability_set.app_set,
    azurerm_key_vault_secret.vmpassword
  ]
}

# Creating Availability Set
resource "azurerm_availability_set" "app_set" {
  name = "app-set"
  location = local.location
  resource_group_name = local.resource_group
  platform_fault_domain_count = 3
  platform_update_domain_count = 3
  depends_on = [
    azurerm_resource_group.application_grp
  ]
}


# Creating Storage Account, Container and Blob
resource "azurerm_storage_account" "tfstate" {
  name                     = "tfstate98145185f"
  resource_group_name      = local.resource_group
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "btfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "blob"
  depends_on = [
    azurerm_storage_account.tfstate
  ]
}
locals {
  main_tags        = merge(var.tags, { env = var.env, state_container_name = var.state_container_name, state_key = var.state_key })
  allowed_list_ips = split(",", coalesce(var.allowed_list_ips, chomp(data.http.icanhazip.response_body)))
  vm_name          = "${var.prefix}-${var.env}-dsw-${var.machine_number}"
}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "random_password" "vm_password" {
  length           = 8
  lower            = true
  special          = true
  override_special = "!#$"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 4
  min_special      = 1
}

resource "azurerm_key_vault_secret" "vm_password" {
  name         = local.vm_name
  value        = random_password.vm_password.result
  key_vault_id = azurerm_key_vault.vm_kv.id
  depends_on = [
    azurerm_key_vault_access_policy.terraform_spn
  ]
}

resource "azurerm_resource_group" "main" {
  name     = "${local.vm_name}-rg"
  location = var.location
  tags     = local.main_tags
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["192.168.0.0/24"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.main_tags
}

resource "azurerm_subnet" "workstation" {
  name                 = "workstation"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["192.168.0.0/27"]
}

resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Dynamic"
  domain_name_label   = lower(local.vm_name)
  tags                = local.main_tags
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic1"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.workstation.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
  tags = local.main_tags
}

resource "azurerm_network_security_group" "access" {
  name                = "${var.prefix}-workstation-access"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "rdp"
    priority                   = 100
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefixes    = local.allowed_list_ips
    destination_port_range     = "3389"
    destination_address_prefix = azurerm_network_interface.main.private_ip_address
  }

  tags = local.main_tags
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.workstation.id
  network_security_group_id = azurerm_network_security_group.access.id
}

resource "azurerm_windows_virtual_machine" "main" {
  name                     = local.vm_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  size                     = var.size
  admin_username           = var.username
  admin_password           = random_password.vm_password.result
  enable_automatic_updates = true
  timezone                 = var.timezone
  network_interface_ids = [
    azurerm_network_interface.main.id
  ]
  boot_diagnostics {
    storage_account_uri = null
  }

  source_image_reference {
    publisher = "microsoft-dsvm"
    offer     = "dsvm-win-2019"
    sku       = "winserver-2019"
    version   = "22.07.18"
  }

  os_disk {
    storage_account_type   = "Standard_LRS"
    caching                = "ReadWrite"
    disk_encryption_set_id = azurerm_disk_encryption_set.vm.id
  }

  tags = local.main_tags

  depends_on = [
    azurerm_key_vault_access_policy.disk_encryption_set
  ]
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "workstation" {
  virtual_machine_id = azurerm_windows_virtual_machine.main.id
  location           = azurerm_resource_group.main.location
  enabled            = true

  daily_recurrence_time = "2230"
  timezone              = var.timezone

  notification_settings {
    enabled = false
  }
}


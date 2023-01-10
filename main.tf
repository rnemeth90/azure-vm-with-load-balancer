resource "azurerm_resource_group" "resource_group" {
  name     = "${var.vm_name}-rg"
  location = var.location
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.vm_name}-pip"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.vm_name}-nsg"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "vm_nic" {
  count               = 2
  name                = "${var.vm_name}-nic-${count.index}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "${var.vm_name}-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_vmnic_association" {
  for_each                  = { for nic in azurerm_network_interface.vm_nic : nic.id => nic }
  network_interface_id      = each.value.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_backend_address_pool_association" "lb_nic_association" {
  for_each                = { for nic in azurerm_network_interface.vm_nic : nic.id => nic }
  network_interface_id    = each.value.id
  ip_configuration_name   = "${var.vm_name}-ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_address_pool.id
}

resource "azurerm_availability_set" "availability_set" {
  name                         = "${var.vm_name}-avset"
  location                     = azurerm_resource_group.resource_group.location
  resource_group_name          = azurerm_resource_group.resource_group.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

resource "azurerm_virtual_machine" "test" {
  count                 = 2
  name                  = "${var.vm_name}-${count.index}"
  location              = azurerm_resource_group.resource_group.location
  resource_group_name   = azurerm_resource_group.resource_group.name
  availability_set_id   = azurerm_availability_set.availability_set.id
  network_interface_ids = [element(azurerm_network_interface.vm_nic.*.id, count.index)]
  vm_size               = var.vm_sku_size

  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.vm_name}-osdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.vm_name}${count.index}"
    admin_username = var.admin_username
    admin_password = random_password.password.result
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "staging"
  }
}

output "admin_password" {
  value = nonsensitive(random_password.password.result)
}

output "admin_username" {
  value = var.admin_username
}

output "public_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
}

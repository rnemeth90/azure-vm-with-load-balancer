resource "azurerm_lb" "load_balancer" {
  name                = "${var.vm_name}-lb"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "${var.vm_name}-pip"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_address_pool" {
  loadbalancer_id = azurerm_lb.load_balancer.id
  name            = "${var.vm_name}-backendPool"
}

variable "vm_name" {
  type    = string
  default = "azrtnvm"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "vm_sku_size" {
  type    = string
  default = "Standard_DS1_v2"
}

variable "admin_username" {
  type    = string
  default = "azure_user"
}

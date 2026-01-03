variable "location" {
  default = "East US"
}

variable "resource_group_name" {
  default = "rg-prod-windows-vm"
}

variable "admin_username" {
  default = "azureadmin"
}

variable "admin_password" {
  sensitive = true
}

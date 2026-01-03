terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tf-state"
    storage_account_name = "tfterraformstate01"
    container_name       = "tfstate"
    key                  = "windows-vm.tfstate"
  }
}

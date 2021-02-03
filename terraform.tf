terraform {
  backend "azurerm" {
    resource_group_name  = "VM-TestVirtualOps"
    storage_account_name = "aztfstateaccount"
    container_name       = "tfstate"
    key                  = "virtaulops.tfstate"
  }
}

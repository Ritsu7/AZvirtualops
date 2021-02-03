virtualOps_rg             = "virtualOpsRG"
virtualOps_location       = "West Europe"
resource_prefix           = "virtualops"
virtualOps_vm_name        = "virtualopsaz"
terraform_script_version  = "1.0.0"
vnet_address_space        = "10.1.0.0/16"
virtualops_subnets        = {
    addssubnet             = "10.1.1.0/24"
    AzureFirewallSubnet    = "10.1.2.0/24"
    workloadsubnet         = "10.1.3.0/24"   
  }
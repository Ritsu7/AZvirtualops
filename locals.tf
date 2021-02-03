locals { 
nsgrules = {
   
    AllowSyncWithAzureAD = {
    name                       = "AllowSyncWithAzureAD"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureActiveDirectoryDomainServices"
    destination_address_prefix = "*"
    }
 
    AllowRDP = {
      name                       = "AllowRDP"
      priority                   = 201
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "CorpNetSaw"
      destination_address_prefix = "*"
    }
 
    AllowPSRemoting = {
      name                       = "AllowPSRemoting"
      priority                   = 201
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "5986"
      source_address_prefix      = "AzureActiveDirectoryDomainServices"
      destination_address_prefix = "*"
    }
  }
 
}
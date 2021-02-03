provider "azurerm" {
  version = "2.45.1"
  features {}
}

resource "azurerm_resource_group" "virtualOps_rg" {
  name     = var.virtualOps_rg
  location = var.virtualOps_location

  tags = {
    Product       = "VirtulOpsRG"
    build-version = var.terraform_script_version
  }
}

resource "azurerm_virtual_network" "virtualops_vnet" {
  name                = "${var.resource_prefix}-vnet"
  location            = var.virtualOps_location
  resource_group_name = azurerm_resource_group.virtualOps_rg.name
  address_space       = [var.vnet_address_space]
}

resource "azurerm_subnet" "virtualops_subnets" {
    for_each = var.virtualops_subnets

    name                 = each.key
    resource_group_name  = azurerm_resource_group.virtualOps_rg.name
    virtual_network_name = azurerm_virtual_network.virtualops_vnet.name
    address_prefix       = each.value
}

resource "azurerm_network_security_group" "aadsNSG" {
  name                = "${var.resource_prefix}-aadsnsg"
  location            = azurerm_resource_group.virtualOps_rg.location
  resource_group_name = azurerm_resource_group.virtualOps_rg.name
}

resource "azurerm_network_security_rule" "nsgrules" {
  for_each                    = local.nsgrules 
  name                        = each.key
  direction                   = each.value.direction
  access                      = each.value.access
  priority                    = each.value.priority
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = azurerm_resource_group.virtualOps_rg.name
  network_security_group_name = azurerm_network_security_group.aadsNSG.name
}

resource "azurerm_subnet_network_security_group_association" "aadsnsg_associate" {
  subnet_id                 = azurerm_subnet.virtualops_subnets["addssubnet"].id
  network_security_group_id = azurerm_network_security_group.aadsNSG.id
}

resource "azurerm_public_ip" "virtualOps_public_ip" {
  name                = "${var.resource_prefix}-public-ip"
  location            = var.virtualOps_location
  resource_group_name = azurerm_resource_group.virtualOps_rg.name
  sku                 = "Standard"
  allocation_method   = "Static"
  
    tags = {
    Product = "VirtualOps-FirewallIP"
  }
}


resource "azurerm_route_table" "private_secure_route" {
  name                          = "secureroute"
  location                      = azurerm_resource_group.virtualOps_rg.location
  resource_group_name           = azurerm_resource_group.virtualOps_rg.name
  disable_bgp_route_propagation = false

  route {
    name                    = "route1"
    address_prefix          = "0.0.0.0/0"
    next_hop_type           = "VirtualAppliance"
    next_hop_in_ip_address  = "10.1.2.4"
  }

  tags = {
    Product = "RouteTable"
  }
}

resource "azurerm_network_interface" "VirtualOpsNIC" {
  name                = "${var.resource_prefix}-nic"
  location            = azurerm_resource_group.virtualOps_rg.location
  resource_group_name = azurerm_resource_group.virtualOps_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.virtualops_subnets["workloadsubnet"].id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.3.2"
  }
}

resource "azurerm_windows_virtual_machine" "SharedVM" {
  name                  = "${var.virtualOps_vm_name}-azterraform"
  resource_group_name   = azurerm_resource_group.virtualOps_rg.name
  location              = azurerm_resource_group.virtualOps_rg.location
  size                  = "Standard_F2"
  admin_username        = "adminuser"
  admin_password        = data.azurerm_key_vault_secret.admin_password.value
  network_interface_ids = [
    azurerm_network_interface.VirtualOpsNIC.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-10"
    sku       = "20h1-evd"
    version   = "latest"
  }

      tags = {
    Product = "VirtualOps-SharedVM"
  }
}

resource "azurerm_firewall" "virtualOps_Firewall" {
  name                = "${var.resource_prefix}-firewall"
  location            = azurerm_resource_group.virtualOps_rg.location
  resource_group_name = azurerm_resource_group.virtualOps_rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.virtualops_subnets["AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.virtualOps_public_ip.id
    private_ip_address   = "10.1.2.4"
  }
  
      tags = {
    Product = "VirtualOps-Firewall"
  }
}

resource "azurerm_firewall_application_rule_collection" "Virtualops_AppRule" {
  name                = "testcollection"
  azure_firewall_name = azurerm_firewall.virtualOps_Firewall.name
  resource_group_name = azurerm_resource_group.virtualOps_rg.name
  priority            = 100
  action              = "Allow"

  rule {
    name = "Allow Portal and ADO"

    source_addresses = [
      "10.1.3.0/24",
    ]

    target_fqdns = [
      "*.aadcdn.microsoftonlinep.com,*.aka.ms,*.applicationinsights.io,*.azure.com,*.azure.net,*.azurefd.net,*.azureapi.net,*.azuredatalakestore.net,*.azureedge.net,*.loganalytics.io,*.microsoft.com,*.microsoftonline.com,*.microsoftonlinep.com,*.msauth.net,*.msftauth.net,*.trafficmanager.net,*.visualstudio.com,*.windows.net,*.windows-int.net",
    ]

    protocol {
      port = "443"
      type = "Https"

    }
  }

 depends_on = [azurerm_firewall.virtualOps_Firewall]

}


resource "azurerm_firewall_nat_rule_collection" "virtualops_NAT" {
  name                = "testcollection"
  azure_firewall_name = azurerm_firewall.virtualOps_Firewall.name
  resource_group_name = azurerm_resource_group.virtualOps_rg.name
  priority            = 100
  action              = "Dnat"

  rule {
    name = "nat for shared vm"

    source_addresses = [
      "*",
    ]

    destination_ports = [
      "3389",
    ]

    destination_addresses = [
      azurerm_public_ip.virtualOps_public_ip.ip_address
    ]

    translated_port = 3389

    translated_address = "10.1.3.2"

    protocols = [
      "TCP",
      "UDP",
    ]
  }

 depends_on = [azurerm_firewall.virtualOps_Firewall]

}

output "virtualOps_public_ip" {
  description = "private ip addresses of the vm nics"
  value       = azurerm_public_ip.virtualOps_public_ip.ip_address
}
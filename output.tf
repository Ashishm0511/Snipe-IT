output "vm_public_ip" {
  value       = azurerm_public_ip.ashish-RG.ip_address
  description = "The Public IP address of the server instance."
}

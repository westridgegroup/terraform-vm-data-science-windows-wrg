output "workstation_dns_name" {
  value = azurerm_public_ip.pip.fqdn
}

output "workstation_name" {
  value = local.vm_name
}

output "workstation_resource_group_name" {
  value = azurerm_resource_group.main.name
}

# Standard Ouput Values

output "state_container_name" {
  value = var.state_container_name
}

output "state_key" {
  value = var.state_key
}

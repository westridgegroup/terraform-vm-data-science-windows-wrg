data "azuread_domains" "default" {
  only_initial = true
}

data "azuread_group" "users_group" {
  display_name = var.users_group
  security_enabled = true
}

locals {
  domain_name = data.azuread_domains.default.domains.0.domain_name
}

output "domain_name" {
  value = local.domain_name
}

output "user_group_members" {
  value = data.azuread_group.users_group.members
}

# RBAC Reader for Resource group for Users
resource "azurerm_role_assignment" "rg_reader" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Reader"
  principal_id         = data.azuread_group.users_group.object_id #var.users_group
}

# RBAC 
resource "azurerm_role_assignment" "rg_data_ower_for_admins" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = data.azuread_group.users_group.object_id
}

# RBAC Contributor for workspace for the "administrators"
resource "azurerm_role_assignment" "contributor_for_admins" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_group.users_group.object_id
}

resource "azurerm_key_vault_access_policy" "users_group" {
  key_vault_id = azurerm_key_vault.vm_kv.id
  for_each = toset(data.azuread_group.users_group.members)
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = each.value

  secret_permissions = [
    "Get",
    "List",
  ]

}

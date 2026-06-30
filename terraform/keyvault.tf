# Key Vault for sensitive data.
# Authorization is done through Azure RBAC (rbac_authorization_enabled = true)
# instead of the legacy access policies. Permissions are therefore granted as
# role assignments (see role_assignments.tf), which is the model the course asks
# for and the recommended Azure approach.
resource "azurerm_key_vault" "main" {
  name                       = "${var.project_name}${var.environment}kv${local.suffix}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  tags                       = local.tags
}

# Example "sensitive" value stored in the Key Vault.
# The web application reads this secret at runtime through the managed identity,
# demonstrating the "key vault for sensitive data" requirement of Part II.
# depends_on ensures the role assignment exists before Terraform writes the
# secret over the Key Vault data plane.
resource "azurerm_key_vault_secret" "app_message" {
  name         = "app-welcome-message"
  value        = "Hello from Azure Key Vault - loaded securely via Managed Identity"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.kv_admin_current_user]
}

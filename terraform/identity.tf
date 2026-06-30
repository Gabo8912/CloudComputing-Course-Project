# User-Assigned Managed Identity.
# This identity is attached to the Web App and is the security principal the
# application uses (via DefaultAzureCredential) to reach Storage and Key Vault.
# No secrets/connection strings are stored in the app: access is granted purely
# through RBAC role assignments (see role_assignments.tf).
resource "azurerm_user_assigned_identity" "app" {
  name                = "${local.name_prefix}-app-id"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.tags
}

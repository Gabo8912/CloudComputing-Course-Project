# --- Role assignments -------------------------------------------------------
# All access is granted explicitly through Azure RBAC. Two principals matter:
#   * the managed identity  -> what the running application is allowed to do
#   * the current user       -> the person running Terraform, so it can seed data

# ---- Storage --------------------------------------------------------------

# The application's managed identity can read AND write blobs (upload + list).
resource "azurerm_role_assignment" "storage_blob_app" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

# The person running Terraform can manage blobs too (useful for testing/seeding).
resource "azurerm_role_assignment" "storage_blob_current_user" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ---- Key Vault ------------------------------------------------------------

# The application's managed identity can read secrets only.
resource "azurerm_role_assignment" "kv_secrets_user_app" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

# The person running Terraform can manage secrets (needed to create the secret).
resource "azurerm_role_assignment" "kv_admin_current_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Storage Account that holds the uploaded images/files.
# The application authenticates against it with Azure AD (the managed identity)
# via RBAC, instead of using the account access keys.
resource "azurerm_storage_account" "main" {
  name                            = "${var.project_name}${var.environment}${local.suffix}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = var.storage_account_tier
  account_replication_type        = var.storage_replication_type
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = local.tags
}

# Blob container where the application stores and lists files.
resource "azurerm_storage_container" "images" {
  name                  = var.images_container_name
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# App Service Plan: the underlying compute for the web app.
resource "azurerm_service_plan" "main" {
  name                = "${local.name_prefix}-plan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = var.app_service_sku
  tags                = local.tags
}

# Linux Web App that hosts the Node.js application.
resource "azurerm_linux_web_app" "main" {
  name                = "${local.name_prefix}-app-${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id
  tags                = local.tags

  # Attach the user-assigned managed identity. This is the identity
  # DefaultAzureCredential picks up at runtime (selected via AZURE_CLIENT_ID).
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  site_config {
    application_stack {
      node_version = var.node_version
    }
    # always_on is not supported on Free (F1) tiers; enabled otherwise.
    always_on = var.app_service_sku != "F1"
  }

  # Configuration consumed by the application. No secrets here: only the names
  # of the resources and the client id of the managed identity to use.
  app_settings = {
    "AZURE_CLIENT_ID"                = azurerm_user_assigned_identity.app.client_id
    "STORAGE_ACCOUNT_NAME"           = azurerm_storage_account.main.name
    "BLOB_CONTAINER"                 = azurerm_storage_container.images.name
    "KEY_VAULT_NAME"                 = azurerm_key_vault.main.name
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "WEBSITE_NODE_DEFAULT_VERSION"   = "~20"
  }
}

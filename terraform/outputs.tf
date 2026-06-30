output "resource_group_name" {
  description = "Name of the resource group holding every resource"
  value       = azurerm_resource_group.main.name
}

output "storage_account_name" {
  description = "Name of the storage account that stores the images/files"
  value       = azurerm_storage_account.main.name
}

output "images_container_name" {
  description = "Blob container used by the application"
  value       = azurerm_storage_container.images.name
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "managed_identity_client_id" {
  description = "Client ID of the user-assigned managed identity used by the app"
  value       = azurerm_user_assigned_identity.app.client_id
}

output "app_service_name" {
  description = "Name of the Linux Web App (used by the deployment pipeline)"
  value       = azurerm_linux_web_app.main.name
}

output "app_service_url" {
  description = "Public URL of the deployed web application"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

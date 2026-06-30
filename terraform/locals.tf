# Centralised naming and shared values so resource files stay clean.
locals {
  # Suffix added to globally-unique names (storage account, key vault, web app).
  suffix = random_string.suffix.result

  # Base prefix combining project + environment, e.g. "clouddevops-dev".
  name_prefix = "${var.project_name}-${var.environment}"

  # Merge the standard tags with the current environment.
  tags = merge(var.tags, {
    environment = var.environment
  })
}

# Random suffix that guarantees globally-unique names across Azure.
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Active identity running Terraform (used for role assignments / tenant id).
data "azurerm_client_config" "current" {}

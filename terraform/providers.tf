# Provider plugins and version constraints (declared dependencies).
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Remote state backend.
  # The storage account / container referenced here are created beforehand by
  # the bootstrap scripts (see ../bootstrap). Values are supplied at init time:
  #   terraform init -backend-config=backend.hcl
  backend "azurerm" {}
}

# Azure provider. The subscription id comes from variables.tf for authentication.
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

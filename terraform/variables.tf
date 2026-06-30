# --- Authentication ---------------------------------------------------------
# Azure Subscription ID used by the azurerm provider to authenticate.
variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# --- Naming / location ------------------------------------------------------
variable "project_name" {
  description = "Short name used as a prefix for every resource"
  type        = string
  default     = "clouddevops"

  validation {
    condition     = can(regex("^[a-z0-9]{3,16}$", var.project_name))
    error_message = "project_name must be 3-16 lowercase alphanumeric characters."
  }
}

variable "location" {
  description = "Azure region where the resources are deployed"
  type        = string
  default     = "germanywestcentral"
}

variable "environment" {
  description = "Deployment environment (dev, test, prod). Used in names and tags."
  type        = string
  default     = "dev"
}

# --- App Service ------------------------------------------------------------
variable "app_service_sku" {
  description = "SKU for the App Service Plan (e.g. B1, S1, F1)"
  type        = string
  default     = "B1"
}

variable "node_version" {
  description = "Node.js runtime version for the Linux Web App"
  type        = string
  default     = "20-lts"
}

# --- Storage ----------------------------------------------------------------
variable "storage_account_tier" {
  description = "Performance tier for the Storage Account"
  type        = string
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Replication strategy for the Storage Account"
  type        = string
  default     = "LRS"
}

variable "images_container_name" {
  description = "Name of the blob container that stores uploaded images/files"
  type        = string
  default     = "images"
}

# --- Tags -------------------------------------------------------------------
variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default = {
    project   = "cloud-devops-project"
    managedBy = "terraform"
    course    = "principles-of-cloud-and-devops"
  }
}

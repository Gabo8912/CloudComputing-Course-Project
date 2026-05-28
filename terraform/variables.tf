# Variable de id de subscripcion de azure, para autenticacion con azure.
variable "subscription_id" {
    description = "Azure Subscription ID"
    type        = string
}

# Variable para la ubicacion de los recursos
variable "location" {
    description = "Azure Region for resources"
    type        = string
    default     = "germanywestcentral"
}

variable "project_name" {
    description = "Name of the project"
    type        = string
    default     = "clouddevops"
}
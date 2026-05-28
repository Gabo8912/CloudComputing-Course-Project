#Definimos los plugins del proyecto (azure) y la version (declaramos dependecia)
terraform {
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
            version = "~> 3.0"
            }
        random = {
        source = "hashicorp/random"
        version = "~> 3.0"
        }
    }
    
}

#Declaramos el provider y el id de subscripcion,que esta en variables.tf, para autentificacion con azure.
provider "azurerm" {
    features {}
    subscription_id = var.subscription_id
}
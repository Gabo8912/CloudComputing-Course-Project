resource "azurerm_resource_group" "main" {
    name     = "${var.project_name}-rg"
    location = var.location
}

#Recurso para generar un string aleatorio, que se utilizara como sufijo para los nombres de los recursos, para evitar conflictos de nombres.
resource "random_string" "suffix" {
    length  = 6
    special = false
    upper   = false
}

resource "azurerm_storage_account" "main" {
    #Definimos el nombre de la cuenta de almacenamiento, utilizando el nombre del proyecto y el sufijo aleatorio generado por el recurso random_string, para evitar conflictos de nombres.
    name                     = "${var.project_name}${random_string.suffix.result}"
    resource_group_name      = azurerm_resource_group.main.name
    location                 = azurerm_resource_group.main.location
    account_tier             = "Standard"
    account_replication_type = "LRS"
}

resource "azurerm_service_plan" "main" {
    name                = "${var.project_name}-plan"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    os_type             = "Linux"
    sku_name            = "F1"
}

resource "azurerm_linux_web_app" "main" {
    name                = "${var.project_name}-app-${random_string.suffix.result}"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    service_plan_id     = azurerm_service_plan.main.id

    site_config {
        always_on = false
    }
}
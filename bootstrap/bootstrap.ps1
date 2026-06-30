<#
.SYNOPSIS
    Scripted prerequisites for the Terraform remote state (PowerShell / Windows).

.DESCRIPTION
    Terraform needs somewhere to keep its state BEFORE it can manage the project
    infrastructure. This is the classic "chicken-and-egg" problem, solved with a
    small bootstrap that creates, with the Azure CLI:
        * a dedicated resource group
        * a storage account
        * a blob container ("tfstate")
    It then writes ../terraform/backend.hcl, which `terraform init` consumes:
        terraform init -backend-config=backend.hcl

.NOTES
    Run once per environment. Requires: az login already done.
#>

param(
    [string]$Location          = "germanywestcentral",
    [string]$StateResourceGroup = "tfstate-rg",
    [string]$ContainerName      = "tfstate"
)

$ErrorActionPreference = "Stop"

Write-Host "==> Using subscription:" -ForegroundColor Cyan
az account show --query "{name:name, id:id}" -o table

# Storage account names are globally unique and max 24 chars -> add a suffix.
$suffix         = -join ((48..57) + (97..122) | Get-Random -Count 6 | ForEach-Object {[char]$_})
$storageAccount = "tfstate$suffix"

Write-Host "==> Creating resource group '$StateResourceGroup' in $Location" -ForegroundColor Cyan
az group create --name $StateResourceGroup --location $Location --output none

Write-Host "==> Creating storage account '$storageAccount'" -ForegroundColor Cyan
az storage account create `
    --name $storageAccount `
    --resource-group $StateResourceGroup `
    --location $Location `
    --sku Standard_LRS `
    --encryption-services blob `
    --min-tls-version TLS1_2 `
    --output none

Write-Host "==> Creating blob container '$ContainerName'" -ForegroundColor Cyan
az storage container create `
    --name $ContainerName `
    --account-name $storageAccount `
    --auth-mode login `
    --output none

$backendPath = Join-Path $PSScriptRoot "..\terraform\backend.hcl"
@"
resource_group_name  = "$StateResourceGroup"
storage_account_name = "$storageAccount"
container_name       = "$ContainerName"
key                  = "clouddevops.tfstate"
"@ | Set-Content -Path $backendPath -Encoding utf8

Write-Host ""
Write-Host "Bootstrap complete." -ForegroundColor Green
Write-Host "Backend config written to terraform/backend.hcl" -ForegroundColor Green
Write-Host "Next:  cd ../terraform  &&  terraform init -backend-config=backend.hcl" -ForegroundColor Yellow

#!/usr/bin/env bash
#
# Scripted prerequisites for the Terraform remote state (Bash / Linux / macOS).
#
# Terraform needs a place to keep its state BEFORE it can manage the project
# infrastructure. This bootstrap creates, with the Azure CLI:
#   * a dedicated resource group
#   * a storage account
#   * a blob container ("tfstate")
# It then writes ../terraform/backend.hcl, consumed by:
#   terraform init -backend-config=backend.hcl
#
# Run once per environment. Requires: `az login` already done.

set -euo pipefail

LOCATION="${LOCATION:-germanywestcentral}"
STATE_RG="${STATE_RG:-tfstate-rg}"
CONTAINER_NAME="${CONTAINER_NAME:-tfstate}"

echo "==> Using subscription:"
az account show --query "{name:name, id:id}" -o table

# Storage account names are globally unique and max 24 chars -> add a suffix.
SUFFIX="$(tr -dc 'a-z0-9' </dev/urandom | head -c6)"
STORAGE_ACCOUNT="tfstate${SUFFIX}"

echo "==> Creating resource group '${STATE_RG}' in ${LOCATION}"
az group create --name "${STATE_RG}" --location "${LOCATION}" --output none

echo "==> Creating storage account '${STORAGE_ACCOUNT}'"
az storage account create \
    --name "${STORAGE_ACCOUNT}" \
    --resource-group "${STATE_RG}" \
    --location "${LOCATION}" \
    --sku Standard_LRS \
    --encryption-services blob \
    --min-tls-version TLS1_2 \
    --output none

echo "==> Creating blob container '${CONTAINER_NAME}'"
az storage container create \
    --name "${CONTAINER_NAME}" \
    --account-name "${STORAGE_ACCOUNT}" \
    --auth-mode login \
    --output none

BACKEND_PATH="$(dirname "$0")/../terraform/backend.hcl"
cat > "${BACKEND_PATH}" <<EOF
resource_group_name  = "${STATE_RG}"
storage_account_name = "${STORAGE_ACCOUNT}"
container_name       = "${CONTAINER_NAME}"
key                  = "clouddevops.tfstate"
EOF

echo ""
echo "Bootstrap complete."
echo "Backend config written to terraform/backend.hcl"
echo "Next:  cd ../terraform && terraform init -backend-config=backend.hcl"

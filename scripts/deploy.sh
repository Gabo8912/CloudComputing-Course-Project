#!/usr/bin/env bash
#
# Build the Node.js app and deploy it to the App Service (manual / local).
#
#   1. Installs production dependencies inside ../app
#   2. Packages the app into a zip
#   3. Deploys the zip with `az webapp deploy`
#
# Resource group and app name default to the Terraform outputs:
#   ./deploy.sh
#   RESOURCE_GROUP=... APP_NAME=... ./deploy.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="${ROOT}/app"
ZIP_PATH="${ROOT}/app.zip"

RESOURCE_GROUP="${RESOURCE_GROUP:-}"
APP_NAME="${APP_NAME:-}"

if [[ -z "${RESOURCE_GROUP}" || -z "${APP_NAME}" ]]; then
  pushd "${ROOT}/terraform" >/dev/null
  [[ -z "${RESOURCE_GROUP}" ]] && RESOURCE_GROUP="$(terraform output -raw resource_group_name)"
  [[ -z "${APP_NAME}" ]] && APP_NAME="$(terraform output -raw app_service_name)"
  popd >/dev/null
fi

echo "==> Installing production dependencies"
( cd "${APP_DIR}" && npm ci --omit=dev )

echo "==> Packaging application -> ${ZIP_PATH}"
rm -f "${ZIP_PATH}"
( cd "${APP_DIR}" && zip -r "${ZIP_PATH}" . -x "node_modules/.cache/*" >/dev/null )

echo "==> Deploying to App Service '${APP_NAME}' (rg: ${RESOURCE_GROUP})"
az webapp deploy \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${APP_NAME}" \
  --src-path "${ZIP_PATH}" \
  --type zip

echo "Deployment complete."

# Cloud DevOps Project
**Principles of Cloud and DevOps Engineering — Summer Semester 2026**
Gabriel Alvarez Arzate – 3017178

A scripted, runnable Infrastructure-as-Code definition for a cloud application
that **stores and displays images in a Storage Account**, using a **Key Vault**
for sensitive data and a **User-Assigned Managed Identity** for authentication.

---

## 1. Description

### Approach
The project is fully described as code and split into three concerns:

| Folder | Responsibility |
| ------ | -------------- |
| `bootstrap/` | Scripted prerequisites: creates the Storage Account that holds the **Terraform remote state** (solves the state chicken-and-egg problem). |
| `terraform/` | Declarative definition of every Azure resource, one file per resource type. |
| `app/` | Node.js + Express test application (Web Page 1 + Web Page 2). |
| `scripts/` | Manual build & deploy helper for the application. |
| `azure-pipelines.yml` | CI/CD build & deployment pipeline for the application. |

### Connections between resources
```
                          ┌──────────────────────────┐
                          │   Resource Group (rg)     │
                          └──────────────────────────┘
                                       │ contains
   ┌───────────────────────┬──────────┴───────────┬────────────────────────┐
   ▼                       ▼                      ▼                         ▼
App Service Plan      Linux Web App          Storage Account            Key Vault
                      (hosts the app)        + "images" container       (RBAC mode)
                           │                                                │
                           │ assigned                                       │
                           ▼                                                │
                 User-Assigned Managed Identity                            │
                           │                                                │
        ┌──────────────────┴─── RBAC role assignments ────────────────────┐│
        ▼                                                                  ▼▼
  Storage Blob Data Contributor                              Key Vault Secrets User
  (read/write blobs)                                         (read the secret)
```

* The **Web App** runs the Node.js app and has the **Managed Identity** attached.
* The app reaches the **Storage Account** and the **Key Vault** purely through
  that identity — there are **no keys or connection strings** anywhere.
* Access is granted explicitly with **RBAC role assignments**.

### Authentication / Identity Context
* **Terraform → Azure:** the `azurerm` provider authenticates with the user's
  `az login` session and `subscription_id`.
* **Application → Azure:** `DefaultAzureCredential` resolves to the
  **user-assigned managed identity** (selected via the `AZURE_CLIENT_ID`
  app setting). The identity holds two RBAC roles:
  * `Storage Blob Data Contributor` on the Storage Account (upload + list).
  * `Key Vault Secrets User` on the Key Vault (read the sensitive value).
* **Key Vault** uses **Azure RBAC authorization** (`rbac_authorization_enabled`),
  not legacy access policies.

---

## 2. Repository Content

```
cloud-devops-project/
├── bootstrap/
│   ├── bootstrap.ps1        # Creates remote-state storage (Windows/PowerShell)
│   └── bootstrap.sh         # Creates remote-state storage (Linux/macOS)
├── terraform/
│   ├── providers.tf         # Provider versions + azurerm remote backend
│   ├── variables.tf         # Configurable parameters (multiple variables)
│   ├── locals.tf            # Naming, tags, random suffix, current identity
│   ├── resource_group.tf    # Resource Group
│   ├── identity.tf          # User-Assigned Managed Identity
│   ├── storage.tf           # Storage Account + "images" container
│   ├── keyvault.tf          # Key Vault (RBAC) + sample secret
│   ├── role_assignments.tf  # RBAC role assignments
│   ├── app_service.tf       # App Service Plan + Linux Web App
│   └── outputs.tf           # Useful outputs (names, URLs, client id)
├── app/
│   ├── server.js            # Express app (list / upload / download)
│   ├── package.json
│   └── views/
│       ├── index.ejs        # Web Page 1 — list blobs + download links
│       └── upload.ejs       # Web Page 2 — upload form
├── scripts/
│   ├── deploy.ps1           # Build + deploy the app (Windows)
│   └── deploy.sh            # Build + deploy the app (Linux/macOS)
├── azure-pipelines.yml      # Build/Deployment pipeline
└── README.MD
```

---

## 3. How to Run

### Prerequisites
- [Azure for Students account](https://azure.microsoft.com/free/students)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Terraform ≥ 1.5](https://developer.hashicorp.com/terraform/install)
- [Node.js ≥ 20](https://nodejs.org)

### Step 1 — Login
```bash
az login
az account show --query id -o tsv   # copy your subscription id
```

### Step 2 — Bootstrap the remote state (scripted prerequisite)
This creates the Storage Account that will hold the Terraform state and writes
`terraform/backend.hcl`.

Windows (PowerShell):
```powershell
cd bootstrap
./bootstrap.ps1
```
Linux/macOS:
```bash
cd bootstrap
chmod +x bootstrap.sh && ./bootstrap.sh
```

### Step 3 — Configure variables
Inside `terraform/`, create `terraform.tfvars`:
```hcl
subscription_id = "your-subscription-id-here"
# Optional overrides:
# project_name    = "clouddevops"
# environment     = "dev"
# location        = "germanywestcentral"
# app_service_sku = "B1"
```

### Step 4 — Deploy the infrastructure
```bash
cd terraform
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

### Step 5 — Deploy the application
**Option A — manual script** (after `terraform apply`):
```bash
# from repo root
./scripts/deploy.sh          # or ./scripts/deploy.ps1 on Windows
```
**Option B — Azure DevOps pipeline:** import `azure-pipelines.yml`, set the
`azureServiceConnection` and `appServiceName` variables, and run it.

The app URL is printed by `terraform output app_service_url`.

---

## 4. Resources Created
- **Resource Group** – container for all resources.
- **User-Assigned Managed Identity** – the application's security principal.
- **Storage Account + `images` container** – stores the uploaded files.
- **Key Vault (RBAC)** – holds a sensitive value read at runtime.
- **Role Assignments** – grant blob and secret access to the identity (and the
  Terraform user).
- **App Service Plan + Linux Web App** – hosts the Node.js application.

## 5. Application (Part II)
- **Web Page 1 (`/`)** — lists every blob in the Storage Account with a
  **download link** for each and a **link to Web Page 2**. Also shows the
  sensitive welcome message read from Key Vault.
- **Web Page 2 (`/upload`)** — form to upload a file/image; the file is stored
  as a blob and you are redirected back to Web Page 1.

## 6. Notes
- `terraform.tfvars` and `backend.hcl` are excluded from version control.
- Resource names include a random suffix to ensure global uniqueness.
- Default region: `germanywestcentral`.
- The application stores **no secrets**: all access uses the managed identity.

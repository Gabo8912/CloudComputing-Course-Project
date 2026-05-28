# Cloud DevOps Project – Part 1
**Principles of Cloud and DevOps Engineering**
Gabriel Alvarez Arzate – 3017178

## Prerequisites
- [Azure Account (Students)](https://azure.microsoft.com/free/students)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Terraform](https://developer.hashicorp.com/terraform/install)
- VS Code with Terraform extension (optional)

## How to Run

**1. Login to Azure**
```bash
az login
```

**2. Get your Subscription ID**
```bash
az account show
```
Copy the `id` field from the output.

**3. Create terraform.tfvars**

Inside the `terraform/` folder, create a file named `terraform.tfvars`:
```hcl
subscription_id = "your-subscription-id-here"
```

**4. Initialize Terraform**
```bash
cd terraform
terraform init
```

**5. Preview changes**
```bash
terraform plan
```

**6. Apply infrastructure**
```bash
terraform apply
```
Type `yes` when prompted.

## Project Structure
cloud-devops-project/
├── terraform/
│   ├── main.tf          # Resource definitions
│   ├── variables.tf     # Configurable parameters
│   ├── outputs.tf       # Output values after deployment
│   └── providers.tf     # Azure provider configuration
└── README.md

## Resources Created
- **Resource Group** – Container for all project resources
- **Storage Account** – Stores images and files (Part II)
- **Key Vault** – Securely stores sensitive credentials (Part II)
- **App Service Plan** – Defines the underlying server hardware
- **App Service** – Hosts the web application (Part II)

## Notes
- `terraform.tfvars` is excluded from version control (.gitignore)
- All resources are deployed to `germanywestcentral`
- Resource names include a random suffix to ensure global uniqueness
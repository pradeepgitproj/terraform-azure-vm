# terraform-azure-vm

This repository contains Terraform configuration to deploy a single Azure Virtual Machine.

**This README explains prerequisites, setup, and the exact commands to deploy and destroy the VM.**

**Prerequisites:**
- An Azure subscription.
- Install Terraform (1.0+ recommended).
- Install Azure CLI (`az`).
- Optional: a service principal for CI/CD (recommended for automation).

**Files (typical)**
- `main.tf` — resources: resource group, network, NIC, VM, public IP.
- `variables.tf` — variable definitions.
- `outputs.tf` — outputs like public IP.
- `terraform.tfvars` or `terraform.tfvars.json` — values for variables (not committed).
- `backend.tf` (optional) — remote state configuration (Azure Storage).

Quick checklist

- Decide whether you'll use local state (default) or an Azure Storage backend.
- Choose authentication method: `az login` (interactive) or a Service Principal (CI).
- Prepare an SSH key for the Linux VM (or use a password-based admin user if required).

Generate SSH key (if you don't have one)

PowerShell:

```powershell
ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\id_rsa -N ""
```

This will create `id_rsa` and `id_rsa.pub` in your `%USERPROFILE%\.ssh` folder. Use the public key value in Terraform variables.

Authentication options

1) Interactive developer (quick):

```powershell
az login
az account set --subscription "<YOUR_SUBSCRIPTION_ID_OR_NAME>"
```

Terraform's AzureRM provider will use the `az` CLI credentials.

2) Service Principal (recommended for automation / CI):

```powershell
az ad sp create-for-rbac --name "tf-azure-vm-sp" --role Contributor --scopes /subscriptions/<SUBSCRIPTION_ID>
```

This command prints JSON with `appId` (client id), `password` (client secret), and `tenant`. Set these as environment variables before running Terraform:

```powershell
$env:ARM_SUBSCRIPTION_ID = "<SUBSCRIPTION_ID>"
$env:ARM_CLIENT_ID = "<appId>"
$env:ARM_CLIENT_SECRET = "<password>"
$env:ARM_TENANT_ID = "<tenant>"
```

Remote state (optional but recommended)

Use an Azure Storage account + container for locking and shared state. Example backend block (put in `backend.tf`):

```hcl
terraform {
	backend "azurerm" {
		resource_group_name  = "rg-terraform-state"
		storage_account_name = "stterraformstate123"
		container_name       = "tfstate"
		key                  = "terraform-azure-vm.tfstate"
	}
}
```

You must create the resource group and storage account (or create them outside Terraform first) before `terraform init` when using this backend.

Recommended variable examples (`terraform.tfvars`)

```hcl
location           = "eastus"
resource_group_name = "rg-terraform-azure-vm"
vm_name            = "demo-vm"
admin_username     = "azureuser"
ssh_public_key     = "<paste contents of id_rsa.pub here>"
# terraform-azure-vm

This repository contains Terraform code to deploy a Windows virtual machine on Azure. The README below is generated from the repository's Terraform configuration and explains what is created, the variables, and exact steps to deploy.

**What this code creates**
- Azure Resource Group (default: `rg-prod-windows-vm`)
- Virtual Network `vnet-prod` and Subnet `subnet-prod`
- Network Security Group `nsg-prod` with an inbound rule allowing RDP (TCP/3389)
- Public IP `pip-vm` (Static)
- Network Interface `nic-vm` attached to the VM
- Windows Virtual Machine `prod-windows-vm` (image: Windows Server 2022 Datacenter, size `Standard_B2s`)

The project uses modules located under `modules/network` and `modules/windows-vm`.

Important files
- `provider.tf` — provider block and required provider version (~> 3.0 for `azurerm`).
- `backend.tf` — Azure Storage backend configured for state (resource group `rg-tf-state`, storage account `tfterraformstate01`, container `tfstate`, key `windows-vm.tfstate`). Ensure these exist or remove/modify `backend.tf` if you prefer local state.
- `main.tf` — top-level resources and module calls.
- `variables.tf` — top-level variable defaults.
- `modules/` — module implementations for network and windows-vm.

Variables (defaults)
- `location` — default: `East US`
- `resource_group_name` — default: `rg-prod-windows-vm`
- `admin_username` — default: `azureadmin`
- `admin_password` — no default; marked `sensitive = true` (required)

Notes about `admin_password`:
- The VM module expects a Windows administrator password. Azure enforces password complexity rules — use a secure, complex password.
- Do not store passwords in VCS. Use one of the methods below to provide it securely.

Authentication to Azure
- Interactive developer:

```powershell
az login
az account set --subscription "<YOUR_SUBSCRIPTION_ID_OR_NAME>"
```

- Service Principal (CI/CD): create one and set the standard ARM environment variables (`ARM_SUBSCRIPTION_ID`, `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`).

Providing variables (recommended approaches)
- Use a `terraform.tfvars` file (add to `.gitignore`) with the `admin_password` set — keep this file secure.

Example `terraform.tfvars` (do not commit):

```hcl
location = "East US"
resource_group_name = "rg-prod-windows-vm"
admin_username = "azureadmin"
admin_password = "P@ssw0rd3xample!"
```

- Or export an environment variable for the password:

PowerShell (temporary for session):

```powershell
#$ plain-text example (avoid in scripts or VCS)
$env:TF_VAR_admin_password = "P@ssw0rd3xample!"
```

Initialize, plan, apply

1) Initialize (this will configure backend and download providers):

```powershell
terraform init
```

If `backend.tf` references the storage account and container that don't exist yet, create them first or remove/adjust `backend.tf`.

2) Create plan and apply:

```powershell
terraform plan -out=tfplan -var-file="terraform.tfvars"
terraform apply "tfplan"
```

Or pass variables inline (not recommended for secrets):

```powershell
terraform plan -out=tfplan -var "resource_group_name=rg-prod-windows-vm" -var "location=East US" -var "admin_username=azureadmin" -var "admin_password=P@ssw0rd3xample!"
terraform apply "tfplan"
```

Get the VM Public IP
- The module creates a public IP resource named `pip-vm` in the target resource group. To retrieve the IP after apply using Azure CLI:

```powershell
az network public-ip show -g <RESOURCE_GROUP_NAME> -n pip-vm --query ipAddress -o tsv
```

RDP to the VM
- Use the public IP returned above and connect with the configured `admin_username` and `admin_password` over RDP (port 3389).

Security recommendations
- The included NSG allows RDP from any public source (`source_address_prefix = "*"`). This is insecure for production. Limit access by specifying trusted IP ranges or use a jumpbox / VPN.
- Consider enabling Azure Just-In-Time (JIT) VM access or an Azure Bastion host.
- Store secrets in Azure Key Vault or use pipeline secret variables for CI/CD.

Destroy resources

When finished, destroy the deployed resources with:

```powershell
terraform destroy -var-file="terraform.tfvars"
```

Troubleshooting
- If `terraform init` fails due to backend configuration, verify the storage account/container exist and permissions are correct.
- If authentication fails, double-check `az login` status or ARM environment variables for a service principal.
- For resource naming conflicts, check the defaults in `variables.tf` and adjust.

Next steps I can help with
- Add an `outputs.tf` to export the VM public IP automatically.
- Restrict NSG rules or add an Azure Bastion/Jumphost module.
- Add a secure method to provide the `admin_password` (Key Vault or managed identity).

If you want, I can now add an `outputs.tf` and a short sample `terraform.tfvars.example` and a `.gitignore` entry to keep secrets out of the repo.


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
vm_size            = "Standard_B1s"
```

Initialize, plan, apply

PowerShell commands to deploy using interactive `az login` or SP environment vars:

```powershell
# initialize terraform (installs provider plugins)
terraform init

# create an execution plan and save it to file
terraform plan -out=tfplan -var-file="terraform.tfvars"

# inspect the plan (optional)
terraform show -json tfplan | Out-File -Encoding utf8 plan.json

# apply the saved plan
terraform apply "tfplan"
```

If you prefer to pass variables directly without a `terraform.tfvars` file:

```powershell
terraform plan -out=tfplan -var "resource_group_name=rg-terraform-azure-vm" -var "location=eastus" -var "admin_username=azureuser" -var "ssh_public_key=$(Get-Content $env:USERPROFILE\.ssh\id_rsa.pub -Raw)"
terraform apply "tfplan"
```

Get the VM public IP (example using output)

If your Terraform configuration defines an output named `public_ip`, run:

```powershell
terraform output public_ip
```

Destroying the infrastructure

When you no longer need the VM, destroy the resources (this will remove everything managed by Terraform in this workspace):

```powershell
terraform destroy -var-file="terraform.tfvars"
```

Troubleshooting

- If Terraform cannot authenticate, verify `az login` session or SP env vars.
- If a backend is configured and `terraform init` fails, ensure the storage account and container exist and that your identity has permissions to access them.
- Check provider plugin versions in `terraform init` output.

Security notes

- Do not commit `terraform.tfvars` if it contains secrets.
- Prefer service principals with least privilege for automation.

Next steps (optional enhancements)

- Add managed identity or Key Vault integration for secrets.
- Harden the VM (NSG rules, disable password auth, system updates).
- Use modules to parameterize multiple environments (dev/staging/prod).

If you want, I can:
- add a sample `main.tf` and `variables.tf` here,
- or scaffold a `backend.tf` and instructions to provision the storage account for remote state.

---

Repository: `terraform-azure-vm`


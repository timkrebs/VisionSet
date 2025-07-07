# VisionSet Terraform Infrastructure

This Terraform configuration provisions the full Azure infrastructure for the VisionSet microservices MVP, including AKS, PostgreSQL, Blob Storage, ACR, and HCP Vault integration.

## Prerequisites
- Azure subscription
- HCP Vault account and cluster
- Terraform >= 1.3
- Azure CLI (`az`), kubectl, and Helm installed

## Setup Steps

1. **Clone this repo and enter the `terraform/` directory:**
   ```sh
   cd terraform
   ```

2. **Configure your variables:**
   - Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values, or set variables via CLI/ENV.
   - Required variables:
     - `azure_subscription_id` (your Azure subscription)
     - `hcp_vault_address` (from HCP Vault UI)
     - `hcp_vault_token` (from HCP Vault UI)

3. **Initialize Terraform:**
   ```sh
   terraform init
   ```

4. **Plan and apply:**
   ```sh
   terraform plan
   terraform apply
   ```

5. **After apply:**
   - AKS kubeconfig will be output (use it with `kubectl`)
   - PostgreSQL FQDN, Storage Account, and ACR login server will be shown
   - The ingress public IP will be available after NGINX is deployed

## HCP Vault Integration
- This config assumes you will use HCP Vault for all secrets (DB credentials, API keys, etc.).
- After AKS is up, follow HCP Vault docs to:
  - Enable Kubernetes auth in Vault
  - Create Vault policies for your microservices
  - Store secrets (e.g., DB password, storage keys) in Vault
  - Configure your Python apps to fetch secrets from Vault at runtime

## DNS and Ingress
- Point your domain (`visionset.app`) to the public IP output for the NGINX ingress controller (after deployment).
- For HTTPS, install cert-manager and configure Let's Encrypt (see AKS/cert-manager docs).
- Use subpaths or subdomains as needed for routing frontend and API services.

## Notes
- All resources are created in the `westeurope` region by default.
- No secrets are output in plaintext; all sensitive data should be managed via Vault.
- For production, review Azure and Vault security best practices. 
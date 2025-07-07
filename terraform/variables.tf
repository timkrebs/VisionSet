variable "azure_subscription_id" {
  description = "The Azure Subscription ID to use."
  type        = string
}

variable "azure_region" {
  description = "The Azure region to deploy resources in."
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "The name of the Azure Resource Group."
  type        = string
  default     = "visionset-rg"
}

variable "hcp_vault_address" {
  description = "The address of the HCP Vault cluster."
  type        = string
}

variable "hcp_vault_token" {
  description = "The token for authenticating with HCP Vault."
  type        = string
  sensitive   = true
} 
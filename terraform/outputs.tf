output "aks_kube_config" {
  description = "Kubeconfig for AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "postgresql_fqdn" {
  description = "FQDN of the PostgreSQL server."
  value       = azurerm_postgresql_flexible_server.db.fqdn
}

output "storage_account_name" {
  description = "Name of the Azure Storage Account for images."
  value       = azurerm_storage_account.images.name
}

output "acr_login_server" {
  description = "Azure Container Registry login server."
  value       = azurerm_container_registry.acr.login_server
}

# Ingress public IP will be available after NGINX is deployed
output "ingress_public_ip" {
  description = "Public IP for the NGINX ingress controller (set after deployment)."
  value       = "Set after NGINX deployment"
} 
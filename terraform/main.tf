resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.azure_region
}

resource "azurerm_container_registry" "acr" {
  name                = "visionsetacr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  admin_enabled       = false
}

resource "azurerm_postgresql_flexible_server" "db" {
  name                   = "visionset-db"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  administrator_login    = "visionsetadmin"
  administrator_password = random_password.db_password.result
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768
  version                = "13"
  zone                   = "1"
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = "visionsetapp"
  server_id = azurerm_postgresql_flexible_server.db.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_storage_account" "images" {
  name                     = "visionsetimages${random_integer.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "random_integer" "suffix" {
  min = 10000
  max = 99999
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "visionset-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "visionset"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "usernp"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_DS2_v2"
  node_count            = 1
}

# NGINX Ingress Controller (placeholder)
resource "kubernetes_namespace" "ingress" {
  metadata {
    name = "ingress-nginx"
  }
}

# HCP Vault integration (placeholder)
# See README for instructions on connecting AKS to HCP Vault 
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "krishanu-sre-gitops-rg"
  location = "centralindia"

  tags = {
    environment    = "demo"
    managed_by     = "terraform"
    owner          = "krishanu"
    ExpirationDate = "2026-10-28"
    note           = "Please do not delete - SRE lab assignment"
  }
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_service_plan" "web" {
  name                = "krishanu-sre-gitops-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "F1"

  tags = azurerm_resource_group.rg.tags
}

resource "azurerm_linux_web_app" "web" {
  name                                           = "krishanu-sre-${random_string.suffix.result}"
  location                                       = azurerm_resource_group.rg.location
  resource_group_name                            = azurerm_resource_group.rg.name
  service_plan_id                                = azurerm_service_plan.web.id
  https_only                                     = true
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false

  site_config {
    minimum_tls_version = "1.2"
    ftps_state          = "Disabled"
    always_on           = false

    application_stack {
      node_version = "22-lts"
    }
  }

  tags = azurerm_resource_group.rg.tags
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "web_app_name" {
  value = azurerm_linux_web_app.web.name
}

output "public_url" {
  value = "https://${azurerm_linux_web_app.web.default_hostname}"
}
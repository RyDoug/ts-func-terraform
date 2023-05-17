terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.50"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.project}-${var.environment}-resource-group"
  location = var.location
}

resource "azurerm_storage_account" "storage_account" {
  name                     = "${var.project}${var.environment}storage"
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_application_insights" "application_insights" {
  name                = "${var.project}-${var.environment}-application-insights"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
  application_type    = "Node.JS"
}

resource "azurerm_service_plan" "app_service_plan" {
  name                = "${var.project}-${var.environment}-app-service-plan"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  os_type             = "Windows"
  sku_name            = "Y1"
}

resource "azurerm_windows_function_app" "function_app" {
  name                = "${var.project}-${var.environment}-func-app"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  service_plan_id     = azurerm_service_plan.app_service_plan.id
  zip_deploy_file     = data.archive_file.function_archive.output_path
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "node",
    "WEBSITE_NODE_DEFAULT_VERSION"   = "~18",
    "FUNCTIONS_EXTENSION_VERSION"    = "~4",
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.application_insights.instrumentation_key
  }

  site_config {
  }
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key
}

data "archive_file" "function_archive" {
  type        = "zip"
  source_dir  = "${var.source-dir}"
  output_path = "${path.module}/files/${var.project}-${var.environment}-${local.timestamp}.zip"
  excludes    = ["dist", "node_modules", "package-lock.json", "local.settings.json", ".vscode"]
}

locals {
  timestamp = formatdate("YYYYMMDDhhmmss", timestamp())
}
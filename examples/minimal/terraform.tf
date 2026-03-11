terraform {
  required_version = ">= 1.13, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.63.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "= 2.8.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "= 3.8.1"
    }
  }
}

provider "azurerm" {
  features {}
}

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azapi = {
        source  = "azure/azapi"
        version = ">= 1.14.0"
      }

    azurerm = {
      source  = "hashicorp/azurerm"
      # v4.40+ includes the AI Foundry resources; stay reasonably fresh
      version = ">= 4.40.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "3ed3444f-de48-4e27-a4c2-e2d4a4cb5848"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {}

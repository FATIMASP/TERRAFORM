# Generate unique RG name: ai102_{random}
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  lower   = true
  numeric = true
  special = false
}

locals {
  rg_name_raw = "${var.rg_name_prefix}_${random_string.suffix.result}"

  # Hub name strategy:
  # Most Azure resource "names" don't allow underscores. To keep you moving,
  # default to a safe hub name that swaps underscores to hyphens.
  hub_name_safe = "${replace(local.rg_name_raw, "_", "-")}-${var.hub_name_suffix}"

  # If you *must* keep underscores (may fail validation), flip 'use_unsafe_hub_name' to true.
  use_unsafe_hub_name = false
  hub_name            = local.use_unsafe_hub_name ? "${local.rg_name_raw}_${var.hub_name_suffix}" : local.hub_name_safe
}

resource "azurerm_resource_group" "rg" {
  name     = local.rg_name_raw
  location = var.location
  tags     = var.tags
}

# Minimal required dependencies for AI Foundry hub (storage + kv)
# Ref: Microsoft Learn hub creation via Terraform. :contentReference[oaicite:1]{index=1}

resource "random_string" "stg" {
  length  = 4
  upper   = false
  lower   = true
  numeric = true
  special = false
}

resource "azurerm_storage_account" "hub" {
  name                     = "st${random_string.stg.result}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = var.tags
}

data "azurerm_client_config" "current" {}

resource "random_string" "kv" {
  length  = 20
  upper   = false
  lower   = true
  numeric = true
  special = false
}

resource "azurerm_key_vault" "hub" {
  name                        = "kv${random_string.kv.result}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  public_network_access_enabled = var.allow_public_network_access
  tags                        = var.tags
}

# Azure AI Foundry (Cognitive Services Account)
resource "azurerm_cognitive_account" "ai_foundry" {
  name                = local.hub_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "OpenAI"
  sku_name            = "S0"

  identity {
    type = "SystemAssigned"
  }

  public_network_access_enabled = var.allow_public_network_access

  tags = var.tags
}

# AI Hub deployment (required for AI Foundry)
resource "azurerm_cognitive_deployment" "ai_hub" {
  name                 = "ai-hub"
  cognitive_account_id = azurerm_cognitive_account.ai_foundry.id
  
  model {
    format  = "OpenAI"
    name    = "gpt-35-turbo"
  }
  
  sku {
    name     = "Standard"
    capacity = 1
  }
}

# AI Project deployment (AI Foundry project)
resource "azurerm_cognitive_deployment" "ai_project" {
  name                 = var.default_project_name
  cognitive_account_id = azurerm_cognitive_account.ai_foundry.id
  
  model {
    format  = "OpenAI"
    name    = "gpt-35-turbo"
  }
  
  sku {
    name     = "Standard"
    capacity = 1
  }
}


# --- Azure AI Foundry additions ---

# Random string for AI Foundry resources
resource "random_string" "st" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_ai_services" "ais" {
  name                = "ais-${random_string.st.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "S0"

  identity {
    type = "SystemAssigned"
  }
}


resource "azurerm_storage_account" "st_ai_foundry" {
  name                     = "st${random_string.st.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}


resource "azurerm_key_vault" "kv_ai_foundry" {
  name                        = "kv-${random_string.st.result}"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  soft_delete_retention_days  = 7
}


resource "azurerm_ai_foundry" "hub" {
  name                = "${azurerm_resource_group.rg.name}-hub"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  storage_account_id  = azurerm_storage_account.st_ai_foundry.id
  key_vault_id        = azurerm_key_vault.kv_ai_foundry.id

  identity {
    type = "SystemAssigned"
  }
}


resource "azurerm_ai_foundry_project" "project" {
  name               = var.default_project_name
  location           = var.location
  ai_services_hub_id = azurerm_ai_foundry.hub.id
  description        = "Provisioned via Terraform"

  identity {
    type = "SystemAssigned"
  }
}



# --- Link Foundry project to Azure OpenAI via ARM (AzAPI) ---
# Creates Microsoft.CognitiveServices/accounts/projects/connections
# Category AzureOpenAI with ApiKey auth, target = OpenAI endpoint, credentials = API key
resource "azapi_resource" "openai_project_connection" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name      = var.openai_connection_name
  parent_id = "${azurerm_ai_services.ais.id}/projects/${azurerm_ai_foundry_project.project.name}"

  # NOTE: This persists your Azure OpenAI API key in TF state. Consider using Key Vault + a post-provision script if that's a problem.
  body = {
    properties = {
      category   = "AzureOpenAI"
      authType   = "ApiKey"
      target     = azurerm_cognitive_account.ai_foundry.endpoint
      credentials = {
        key = azurerm_cognitive_account.ai_foundry.primary_access_key
      }
    }
  }
}

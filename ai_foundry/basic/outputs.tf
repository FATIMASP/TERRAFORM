output "resource_group_name" {
  description = "The name of the created resource group"
  value       = azurerm_resource_group.rg.name
}

# Azure AI Foundry (hub + project)
output "ai_foundry_hub_name" {
  description = "AI Foundry hub name"
  value       = azurerm_ai_foundry.hub.name
}

output "ai_foundry_hub_id" {
  description = "AI Foundry hub resource ID"
  value       = azurerm_ai_foundry.hub.id
}

output "ai_foundry_project_name" {
  description = "AI Foundry project name"
  value       = azurerm_ai_foundry_project.project.name
}

# Backing AI Services and OpenAI
output "ai_services_account_name" {
  description = "Azure AI Services (backing) account name"
  value       = azurerm_ai_services.ais.name
}

# Connection name created via AzAPI
output "openai_connection_name" {
  description = "Connection name in the Foundry project to Azure OpenAI"
  value       = var.openai_connection_name
}


output "ai_foundry_name" {
  description = "The name of the AI Foundry instance (LEGACY: actually Azure OpenAI Cognitive Account)"
  value       = azurerm_cognitive_account.ai_foundry.name
}



output "ai_foundry_endpoint" {
  description = "The endpoint of the AI Foundry instance (LEGACY: actually Azure OpenAI Cognitive Account)"
  value       = azurerm_cognitive_account.ai_foundry.endpoint
}



output "ai_foundry_id" {
  description = "The ID of the AI Foundry instance (LEGACY: actually Azure OpenAI Cognitive Account)"
  value       = azurerm_cognitive_account.ai_foundry.id
}


# Alias (clearer naming)
output "azure_openai_name" {
  description = "Azure OpenAI Cognitive Account name"
  value       = azurerm_cognitive_account.ai_foundry.name
}

# Alias (clearer naming)
output "azure_openai_endpoint" {
  description = "Azure OpenAI Cognitive Account endpoint"
  value       = azurerm_cognitive_account.ai_foundry.endpoint
}

# Alias (clearer naming)
output "azure_openai_id" {
  description = "Azure OpenAI Cognitive Account id"
  value       = azurerm_cognitive_account.ai_foundry.id
}

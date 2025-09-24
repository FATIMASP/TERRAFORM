variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus"
}

variable "rg_name_prefix" {
  description = "Prefix for the resource group"
  type        = string
  default     = "ai102"
}

variable "hub_name_suffix" {
  description = "Suffix used for the AI Foundry hub name."
  type        = string
  default     = "udemylab23"
}

variable "default_project_name" {
  description = "Default AI Foundry project name to create."
  type        = string
  default     = "udemy"
}

variable "allow_public_network_access" {
  description = "If true, enables public network access on the hub (All networks can access)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default = {
    ai102                    = "true"
    ai01                     = "Azure AI Foundry"
    ai01_project             = "Azure AI Foundry project"
    environment              = "lab"
  }
}

# Connection name for the Foundry project -> Azure OpenAI link
variable "openai_connection_name" {
  description = "Name for the Azure OpenAI connection in the Foundry project"
  type        = string
  default     = "azureopenai-default"
}

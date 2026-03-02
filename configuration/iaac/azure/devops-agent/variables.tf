# Azure Authentication
variable "client_id" {
  description = "Azure Service Principal Client ID"
  type        = string
}

variable "client_secret" {
  description = "Azure Service Principal Client Secret"
  type        = string
  sensitive   = true
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

# Azure DevOps Configuration
variable "azdo_org_name" {
  description = "Azure DevOps organization name (e.g., 'myorg' from https://dev.azure.com/myorg)"
  type        = string
}

variable "azdo_pat" {
  description = "Azure DevOps Personal Access Token with 'Agent Pools (read, manage)' scope"
  type        = string
  sensitive   = true
}

variable "azdo_agent_pool" {
  description = "Name of the agent pool to register the agent with"
  type        = string
  default     = "Default"
}

variable "agent_name" {
  description = "Prefix for the agent name (hostname will be appended)"
  type        = string
  default     = "self-hosted"
}

# Resource Configuration
variable "resource_group" {
  description = "Resource group name prefix"
  type        = string
  default     = "devops_agent_rg"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "swedencentral"
}

# VM Configuration
variable "vm_size" {
  description = "Size of the VM (e.g., Standard_B1s, Standard_B2s)"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "Path to SSH public key file for VM access"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "os_disk_size_gb" {
  description = "Size of the OS disk in GB"
  type        = number
  default     = 50
}

# Network Configuration
variable "enable_public_ip" {
  description = "Whether to assign a public IP to the VM"
  type        = bool
  default     = true
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH access (use your IP for security)"
  type        = string
  default     = "*"  # Restrict this in production!
}

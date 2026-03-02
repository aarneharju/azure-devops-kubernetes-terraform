# Sensitive values (client_id, client_secret, subscription_id, tenant_id,
# azdo_org_name, azdo_pat) are injected via Infisical environment variables.

# Azure DevOps Configuration
azdo_agent_pool = "SelfHosted"
agent_name      = "ah2-adkt-terraform-agent-01"

# Resource Configuration
resource_group = "devops_agent_rg"
environment    = "dev"
location       = "swedencentral"

# VM Configuration
vm_size         = "Standard_B1s"   # 1 vCPU, 1 GB RAM - upgrade if builds are slow
admin_username  = "azureuser"
ssh_public_key  = "~/.ssh/id_rsa.pub"
os_disk_size_gb = 50

# Network Configuration
enable_public_ip = true
allowed_ssh_cidr = "*"    # Restrict SSH access to your IP

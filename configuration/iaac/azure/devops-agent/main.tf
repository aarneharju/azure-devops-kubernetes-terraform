provider "azurerm" {
  features {}
  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "devops_agent" {
  name     = "${var.resource_group}_${var.environment}"
  location = var.location
  tags = {
    environment = var.environment
  }
}

# Virtual Network
resource "azurerm_virtual_network" "devops_agent" {
  name                = "devops-agent-vnet-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.devops_agent.location
  resource_group_name = azurerm_resource_group.devops_agent.name
  tags = {
    environment = var.environment
  }
}

# Subnet
resource "azurerm_subnet" "devops_agent" {
  name                 = "devops-agent-subnet"
  resource_group_name  = azurerm_resource_group.devops_agent.name
  virtual_network_name = azurerm_virtual_network.devops_agent.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "devops_agent" {
  name                = "devops-agent-nsg-${var.environment}"
  location            = azurerm_resource_group.devops_agent.location
  resource_group_name = azurerm_resource_group.devops_agent.name

  # Allow SSH (optional - for debugging)
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_cidr
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.environment
  }
}

# Subnet NSG Association
resource "azurerm_subnet_network_security_group_association" "devops_agent" {
  subnet_id                 = azurerm_subnet.devops_agent.id
  network_security_group_id = azurerm_network_security_group.devops_agent.id
}

# Public IP (optional - set enable_public_ip to false if not needed)
resource "azurerm_public_ip" "devops_agent" {
  count               = var.enable_public_ip ? 1 : 0
  name                = "devops-agent-pip-${var.environment}"
  location            = azurerm_resource_group.devops_agent.location
  resource_group_name = azurerm_resource_group.devops_agent.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    environment = var.environment
  }
}

# Network Interface
resource "azurerm_network_interface" "devops_agent" {
  name                = "devops-agent-nic-${var.environment}"
  location            = azurerm_resource_group.devops_agent.location
  resource_group_name = azurerm_resource_group.devops_agent.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.devops_agent.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.enable_public_ip ? azurerm_public_ip.devops_agent[0].id : null
  }

  tags = {
    environment = var.environment
  }
}

# Cloud-init script for Azure DevOps agent installation
locals {
  cloud_init_script = <<-EOF
    #!/bin/bash
    set -e

    # Wait for network/DNS to be ready
    for i in $(seq 1 30); do
      if curl -sf --max-time 5 https://api.github.com > /dev/null 2>&1; then
        echo "Network is ready"
        break
      fi
      echo "Waiting for network... attempt $i/30"
      sleep 10
    done

    # Update system
    apt-get update
    apt-get upgrade -y

    # Install dependencies
    apt-get install -y curl git jq libicu70 libssl3

    # Install Docker (optional but recommended for pipeline builds)
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker ${var.admin_username}

    # Create agent directory
    AGENT_DIR="/opt/azdo-agent"
    mkdir -p $AGENT_DIR
    cd $AGENT_DIR

    # Download latest Azure DevOps agent
    AZP_AGENT_RESPONSE=$(curl -sL "https://api.github.com/repos/microsoft/azure-pipelines-agent/releases/latest")
    AGENT_VERSION=$(echo $AZP_AGENT_RESPONSE | jq -r '.tag_name' | sed 's/v//')
    AGENT_URL="https://download.agent.dev.azure.com/agent/$AGENT_VERSION/vsts-agent-linux-x64-$AGENT_VERSION.tar.gz"

    curl -fkSL -o agent.tar.gz "$AGENT_URL"
    tar -zxf agent.tar.gz
    rm agent.tar.gz

    # Set ownership
    chown -R ${var.admin_username}:${var.admin_username} $AGENT_DIR

    # Configure the agent
    sudo -u ${var.admin_username} ./config.sh --unattended \
      --url "https://dev.azure.com/${var.azdo_org_name}" \
      --auth pat \
      --token "${var.azdo_pat}" \
      --pool "${var.azdo_agent_pool}" \
      --agent "${var.agent_name}-$(hostname)" \
      --acceptTeeEula \
      --replace

    # Install and start the agent service
    ./svc.sh install ${var.admin_username}
    ./svc.sh start

    echo "Azure DevOps agent installation complete"
  EOF
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "devops_agent" {
  name                = "devops-agent-${var.environment}"
  resource_group_name = azurerm_resource_group.devops_agent.name
  location            = azurerm_resource_group.devops_agent.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.devops_agent.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(local.cloud_init_script)

  tags = {
    environment = var.environment
  }
}

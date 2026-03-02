output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.devops_agent.name
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.devops_agent.name
}

output "vm_private_ip" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.devops_agent.private_ip_address
}

output "vm_public_ip" {
  description = "Public IP address of the VM (if enabled)"
  value       = var.enable_public_ip ? azurerm_public_ip.devops_agent[0].ip_address : null
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = var.enable_public_ip ? "ssh ${var.admin_username}@${azurerm_public_ip.devops_agent[0].ip_address}" : "ssh ${var.admin_username}@${azurerm_network_interface.devops_agent.private_ip_address}"
}

output "agent_pool" {
  description = "Agent pool where the agent is registered"
  value       = var.azdo_agent_pool
}

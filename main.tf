terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Variables for SCVMM connection
variable "scvmm_server" {
  description = "SCVMM server hostname or IP address"
  type        = string
}

variable "scvmm_username" {
  description = "Username for SCVMM authentication"
  type        = string
}

variable "scvmm_password" {
  description = "Password for SCVMM authentication"
  type        = string
  sensitive   = true
}

variable "vm_name" {
  description = "Name of the VM to turn off"
  type        = string
}

# Local values for PowerShell script paths
locals {
  scripts_dir = "${path.module}/scripts"
}

# Null resource to execute VM shutdown via SCVMM
resource "null_resource" "vm_shutdown" {
  triggers = {
    vm_name = var.vm_name
    always_run = timestamp()
  }

  # Execute PowerShell script to turn off VM via SCVMM
  provisioner "local-exec" {
    command = "bash ${local.scripts_dir}/shutdown_vm.sh"
    environment = {
      SCVMM_SERVER   = var.scvmm_server
      SCVMM_USERNAME = var.scvmm_username
      SCVMM_PASSWORD = var.scvmm_password
      VM_NAME        = var.vm_name
    }
  }
}

# Output the VM status
output "vm_shutdown_status" {
  value = "VM shutdown command executed for: ${var.vm_name}"
}

output "scvmm_server" {
  value = var.scvmm_server
}

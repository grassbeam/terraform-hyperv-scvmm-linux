# Terraform configuration for multiple VMs
terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Variable for multiple VMs
variable "vms" {
  description = "List of VMs to manage"
  type = list(object({
    name      = string
    operation = string # shutdown, start, or status
  }))
  default = []
}

# SCVMM connection variables (same as main.tf)
variable "scvmm_server_multi" {
  description = "SCVMM server hostname or IP address"
  type        = string
}

variable "scvmm_username_multi" {
  description = "Username for SCVMM authentication"
  type        = string
}

variable "scvmm_password_multi" {
  description = "Password for SCVMM authentication"
  type        = string
  sensitive   = true
}

# Local values
locals {
  scripts_dir_multi = "${path.module}/scripts"
}

# Resource for managing multiple VMs
resource "null_resource" "vm_multi_operation" {
  for_each = { for vm in var.vms : vm.name => vm }

  triggers = {
    vm_name   = each.value.name
    operation = each.value.operation
    timestamp = timestamp()
  }

  # Execute the appropriate script based on operation
  provisioner "local-exec" {
    command = "bash ${local.scripts_dir_multi}/${each.value.operation}_vm.sh"
    environment = {
      SCVMM_SERVER   = var.scvmm_server_multi
      SCVMM_USERNAME = var.scvmm_username_multi
      SCVMM_PASSWORD = var.scvmm_password_multi
      VM_NAME        = each.value.name
    }
  }
}

# Data source to check status of multiple VMs
data "external" "vm_multi_status" {
  for_each = { for vm in var.vms : vm.name => vm }
  
  program = ["bash", "${local.scripts_dir_multi}/get_vm_status_json.sh"]
  
  query = {
    scvmm_server   = var.scvmm_server_multi
    scvmm_username = var.scvmm_username_multi
    scvmm_password = var.scvmm_password_multi
    vm_name        = each.value.name
  }
  
  depends_on = [null_resource.vm_multi_operation]
}

# Outputs for multiple VMs
output "multi_vm_results" {
  value = {
    for vm_name, vm_data in data.external.vm_multi_status : vm_name => {
      name             = try(vm_data.result.name, vm_name)
      status           = try(vm_data.result.status, "unknown")
      host             = try(vm_data.result.host, "unknown")
      operating_system = try(vm_data.result.operating_system, "unknown")
      cpu_count        = try(vm_data.result.cpu_count, "unknown")
      memory_mb        = try(vm_data.result.memory_mb, "unknown")
      operation        = var.vms[index(var.vms.*.name, vm_name)].operation
    }
  }
  description = "Results for all VM operations"
}

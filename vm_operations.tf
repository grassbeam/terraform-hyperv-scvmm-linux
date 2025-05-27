# Additional Terraform configuration for VM management operations

# Variable for operation type
variable "operation" {
  description = "Operation to perform: shutdown, start, or status"
  type        = string
  default     = "shutdown"
  validation {
    condition     = contains(["shutdown", "start", "status"], var.operation)
    error_message = "Operation must be one of: shutdown, start, status."
  }
}

# Conditional resource for VM operations
resource "null_resource" "vm_operation" {
  triggers = {
    vm_name   = var.vm_name
    operation = var.operation
    timestamp = timestamp()
  }

  # Execute the appropriate script based on operation
  provisioner "local-exec" {
    command = "bash ${local.scripts_dir}/${var.operation}_vm.sh"
    environment = {
      SCVMM_SERVER   = var.scvmm_server
      SCVMM_USERNAME = var.scvmm_username
      SCVMM_PASSWORD = var.scvmm_password
      VM_NAME        = var.vm_name
    }
  }
}

# Data source to check VM status
data "external" "vm_status" {
  program = ["bash", "${local.scripts_dir}/get_vm_status_json.sh"]
  
  query = {
    scvmm_server   = var.scvmm_server
    scvmm_username = var.scvmm_username
    scvmm_password = var.scvmm_password
    vm_name        = var.vm_name
  }
  
  depends_on = [null_resource.vm_operation]
}

# Output VM operation result
output "vm_operation_result" {
  value = "Operation '${var.operation}' executed for VM: ${var.vm_name}"
}

output "operation_timestamp" {
  value = timestamp()
}

# Additional outputs for VM status information
output "vm_current_status" {
  value       = try(data.external.vm_status.result.status, "unknown")
  description = "Current status of the VM"
}

output "vm_host" {
  value       = try(data.external.vm_status.result.host, "unknown")
  description = "Current host server running the VM"
}

output "vm_details" {
  value = {
    name             = try(data.external.vm_status.result.name, var.vm_name)
    status           = try(data.external.vm_status.result.status, "unknown")
    host             = try(data.external.vm_status.result.host, "unknown")
    operating_system = try(data.external.vm_status.result.operating_system, "unknown")
    cpu_count        = try(data.external.vm_status.result.cpu_count, "unknown")
    memory_mb        = try(data.external.vm_status.result.memory_mb, "unknown")
    creation_time    = try(data.external.vm_status.result.creation_time, "unknown")
    owner            = try(data.external.vm_status.result.owner, "unknown")
    cloud            = try(data.external.vm_status.result.cloud, "unknown")
  }
  description = "Detailed VM information"
}

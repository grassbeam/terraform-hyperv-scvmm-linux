# Makefile for SCVMM Terraform operations

.PHONY: help setup test init plan apply destroy clean status start shutdown multi-shutdown multi-start multi-status

# Default target
help:
	@echo "SCVMM Terraform Management"
	@echo "========================="
	@echo ""
	@echo "Setup commands:"
	@echo "  make setup          - Setup environment and initialize Terraform"
	@echo "  make test           - Run connectivity and configuration tests"
	@echo "  make init           - Initialize Terraform"
	@echo ""
	@echo "Single VM operations:"
	@echo "  make plan           - Show Terraform execution plan"
	@echo "  make shutdown       - Shutdown the VM"
	@echo "  make start          - Start the VM"
	@echo "  make status         - Get VM status"
	@echo "  make apply          - Apply Terraform configuration (default: shutdown)"
	@echo "  make destroy        - Destroy Terraform state"
	@echo ""
	@echo "Multiple VM operations:"
	@echo "  make multi-shutdown - Shutdown multiple VMs"
	@echo "  make multi-start    - Start multiple VMs"
	@echo "  make multi-status   - Get status of multiple VMs"
	@echo ""
	@echo "Utility commands:"
	@echo "  make clean          - Clean temporary files"
	@echo "  make install-deps   - Install dependencies (PowerShell, jq)"
	@echo ""
	@echo "Configuration files:"
	@echo "  terraform.tfvars           - Single VM configuration"
	@echo "  terraform.tfvars.multi     - Multiple VMs configuration"

# Setup environment
setup:
	@echo "Setting up SCVMM Terraform environment..."
	./setup.sh

# Install dependencies
install-deps:
	@echo "Installing dependencies..."
	@if ! command -v pwsh >/dev/null 2>&1; then \
		echo "Installing PowerShell Core..."; \
		./scripts/install_powershell.sh; \
	fi
	@if ! command -v jq >/dev/null 2>&1; then \
		echo "Installing jq..."; \
		if [[ "$$OSTYPE" == "darwin"* ]]; then \
			brew install jq; \
		elif command -v apt-get >/dev/null 2>&1; then \
			sudo apt-get update && sudo apt-get install -y jq; \
		elif command -v yum >/dev/null 2>&1; then \
			sudo yum install -y jq; \
		fi \
	fi

# Test configuration
test:
	@echo "Running SCVMM connectivity tests..."
	./test.sh

# Initialize Terraform
init:
	@echo "Initializing Terraform..."
	terraform init

# Show plan
plan:
	@echo "Showing Terraform plan..."
	terraform plan

# Apply configuration (default operation)
apply:
	@echo "Applying Terraform configuration..."
	terraform apply

# VM Operations
shutdown:
	@echo "Shutting down VM..."
	terraform apply -var='operation=shutdown' -auto-approve

start:
	@echo "Starting VM..."
	terraform apply -var='operation=start' -auto-approve

status:
	@echo "Getting VM status..."
	terraform apply -var='operation=status' -auto-approve

# Multiple VM operations
multi-shutdown:
	@echo "Shutting down multiple VMs..."
	@if [ ! -f terraform.tfvars.multi ]; then \
		echo "Error: terraform.tfvars.multi not found"; \
		echo "Copy terraform.tfvars.multi.example to terraform.tfvars.multi and configure it"; \
		exit 1; \
	fi
	terraform apply -var-file="terraform.tfvars.multi" -target="null_resource.vm_multi_operation" -auto-approve

multi-start:
	@echo "Starting multiple VMs..."
	@if [ ! -f terraform.tfvars.multi ]; then \
		echo "Error: terraform.tfvars.multi not found"; \
		echo "Copy terraform.tfvars.multi.example to terraform.tfvars.multi and configure it"; \
		exit 1; \
	fi
	@# Update operations to start in terraform.tfvars.multi
	terraform apply -var-file="terraform.tfvars.multi" -target="null_resource.vm_multi_operation" -auto-approve

multi-status:
	@echo "Getting status of multiple VMs..."
	@if [ ! -f terraform.tfvars.multi ]; then \
		echo "Error: terraform.tfvars.multi not found"; \
		echo "Copy terraform.tfvars.multi.example to terraform.tfvars.multi and configure it"; \
		exit 1; \
	fi
	terraform apply -var-file="terraform.tfvars.multi" -target="data.external.vm_multi_status" -auto-approve

# Destroy
destroy:
	@echo "Destroying Terraform state..."
	terraform destroy -auto-approve

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	rm -f *.tfplan
	rm -f *.tfstate.backup
	rm -f .terraform.lock.hcl
	rm -rf .terraform/

# Manual script execution helpers
manual-shutdown:
	@echo "Running manual VM shutdown..."
	@if [ ! -f terraform.tfvars ]; then \
		echo "Error: terraform.tfvars not found"; \
		exit 1; \
	fi
	@export SCVMM_SERVER=$$(grep -E '^scvmm_server' terraform.tfvars | cut -d'"' -f2) && \
	export SCVMM_USERNAME=$$(grep -E '^scvmm_username' terraform.tfvars | cut -d'"' -f2) && \
	export SCVMM_PASSWORD=$$(grep -E '^scvmm_password' terraform.tfvars | cut -d'"' -f2) && \
	export VM_NAME=$$(grep -E '^vm_name' terraform.tfvars | cut -d'"' -f2) && \
	./scripts/shutdown_vm.sh

manual-start:
	@echo "Running manual VM start..."
	@if [ ! -f terraform.tfvars ]; then \
		echo "Error: terraform.tfvars not found"; \
		exit 1; \
	fi
	@export SCVMM_SERVER=$$(grep -E '^scvmm_server' terraform.tfvars | cut -d'"' -f2) && \
	export SCVMM_USERNAME=$$(grep -E '^scvmm_username' terraform.tfvars | cut -d'"' -f2) && \
	export SCVMM_PASSWORD=$$(grep -E '^scvmm_password' terraform.tfvars | cut -d'"' -f2) && \
	export VM_NAME=$$(grep -E '^vm_name' terraform.tfvars | cut -d'"' -f2) && \
	./scripts/start_vm.sh

manual-status:
	@echo "Running manual VM status check..."
	@if [ ! -f terraform.tfvars ]; then \
		echo "Error: terraform.tfvars not found"; \
		exit 1; \
	fi
	@export SCVMM_SERVER=$$(grep -E '^scvmm_server' terraform.tfvars | cut -d'"' -f2) && \
	export SCVMM_USERNAME=$$(grep -E '^scvmm_username' terraform.tfvars | cut -d'"' -f2) && \
	export SCVMM_PASSWORD=$$(grep -E '^scvmm_password' terraform.tfvars | cut -d'"' -f2) && \
	export VM_NAME=$$(grep -E '^vm_name' terraform.tfvars | cut -d'"' -f2) && \
	./scripts/get_vm_status.sh

#!/bin/bash

# Quick setup script for the Terraform SCVMM project

set -e

echo "=== Terraform SCVMM Setup Script ==="
echo

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "Checking prerequisites..."

# Check Terraform
if command_exists terraform; then
    echo "✓ Terraform found: $(terraform --version | head -n1)"
else
    echo "✗ Terraform not found. Please install Terraform first."
    echo "  Visit: https://www.terraform.io/downloads.html"
    exit 1
fi

# Check PowerShell Core
if command_exists pwsh; then
    echo "✓ PowerShell Core found: $(pwsh --version)"
else
    echo "✗ PowerShell Core not found."
    echo "  Would you like to install it? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Running PowerShell installation script..."
        ./scripts/install_powershell.sh
    else
        echo "Please install PowerShell Core manually:"
        echo "  macOS: brew install powershell"
        echo "  Linux: See scripts/install_powershell.sh"
        exit 1
    fi
fi

# Check jq (needed for JSON parsing)
if command_exists jq; then
    echo "✓ jq found"
else
    echo "✗ jq not found. Installing jq..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command_exists brew; then
            brew install jq
        else
            echo "Please install jq manually: brew install jq"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command_exists apt-get; then
            sudo apt-get update && sudo apt-get install -y jq
        elif command_exists yum; then
            sudo yum install -y jq
        elif command_exists dnf; then
            sudo dnf install -y jq
        else
            echo "Please install jq manually for your Linux distribution"
            exit 1
        fi
    fi
fi

echo
echo "=== Configuration Setup ==="

# Create terraform.tfvars if it doesn't exist
if [[ ! -f "terraform.tfvars" ]]; then
    echo "Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo "✓ Created terraform.tfvars"
    echo "  Please edit terraform.tfvars with your actual SCVMM settings"
else
    echo "✓ terraform.tfvars already exists"
fi

echo
echo "=== Terraform Initialization ==="

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

echo
echo "=== Setup Complete ==="
echo
echo "Next steps:"
echo "1. Edit terraform.tfvars with your SCVMM server details"
echo "2. Test connectivity: ./scripts/get_vm_status.sh"
echo "3. Run Terraform: terraform plan && terraform apply"
echo
echo "For multiple VMs:"
echo "1. Copy terraform.tfvars.multi.example to terraform.tfvars"
echo "2. Use multi_vm.tf configuration"
echo
echo "Usage examples:"
echo "  # Single VM shutdown"
echo "  terraform apply"
echo
echo "  # Single VM startup"
echo "  terraform apply -var='operation=start'"
echo
echo "  # VM status check"
echo "  terraform apply -var='operation=status'"
echo

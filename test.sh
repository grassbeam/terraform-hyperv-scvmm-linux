#!/bin/bash

# Test script to validate SCVMM connectivity and VM operations

set -e

echo "=== SCVMM Terraform Test Script ==="
echo

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if terraform.tfvars exists
if [[ ! -f "terraform.tfvars" ]]; then
    echo "Error: terraform.tfvars not found"
    echo "Please copy terraform.tfvars.example to terraform.tfvars and configure it"
    exit 1
fi

# Extract variables from terraform.tfvars
echo "Reading configuration from terraform.tfvars..."
SCVMM_SERVER=$(grep -E '^scvmm_server' terraform.tfvars | cut -d'"' -f2)
SCVMM_USERNAME=$(grep -E '^scvmm_username' terraform.tfvars | cut -d'"' -f2)
SCVMM_PASSWORD=$(grep -E '^scvmm_password' terraform.tfvars | cut -d'"' -f2)
VM_NAME=$(grep -E '^vm_name' terraform.tfvars | cut -d'"' -f2)

if [[ -z "$SCVMM_SERVER" || -z "$SCVMM_USERNAME" || -z "$SCVMM_PASSWORD" || -z "$VM_NAME" ]]; then
    echo "Error: Missing required configuration in terraform.tfvars"
    echo "Required: scvmm_server, scvmm_username, scvmm_password, vm_name"
    exit 1
fi

echo "✓ Configuration loaded:"
echo "  SCVMM Server: $SCVMM_SERVER"
echo "  Username: $SCVMM_USERNAME"
echo "  VM Name: $VM_NAME"
echo

# Test 1: Check prerequisites
echo "=== Test 1: Prerequisites ==="
if command_exists pwsh; then
    echo "✓ PowerShell Core available"
else
    echo "✗ PowerShell Core not found"
    exit 1
fi

if command_exists jq; then
    echo "✓ jq available"
else
    echo "✗ jq not found"
    exit 1
fi

if command_exists terraform; then
    echo "✓ Terraform available"
else
    echo "✗ Terraform not found"
    exit 1
fi

echo

# Test 2: SCVMM connectivity and VM status
echo "=== Test 2: SCVMM Connectivity ==="
export SCVMM_SERVER SCVMM_USERNAME SCVMM_PASSWORD VM_NAME

echo "Testing SCVMM connection and VM status..."
if ./scripts/get_vm_status.sh; then
    echo "✓ SCVMM connectivity test passed"
else
    echo "✗ SCVMM connectivity test failed"
    echo "Please check:"
    echo "  - Network connectivity to SCVMM server"
    echo "  - Credentials and permissions"
    echo "  - VM name spelling and case"
    exit 1
fi

echo

# Test 3: JSON status output
echo "=== Test 3: JSON Status Output ==="
echo "Testing JSON status output for Terraform..."
JSON_OUTPUT=$(./scripts/get_vm_status_json.sh)
if echo "$JSON_OUTPUT" | jq . >/dev/null 2>&1; then
    echo "✓ JSON output test passed"
    echo "VM Status JSON:"
    echo "$JSON_OUTPUT" | jq .
else
    echo "✗ JSON output test failed"
    echo "Raw output: $JSON_OUTPUT"
    exit 1
fi

echo

# Test 4: Terraform validation
echo "=== Test 4: Terraform Validation ==="
echo "Validating Terraform configuration..."
if terraform validate; then
    echo "✓ Terraform validation passed"
else
    echo "✗ Terraform validation failed"
    exit 1
fi

echo

# Test 5: Terraform plan
echo "=== Test 5: Terraform Plan ==="
echo "Running Terraform plan..."
if terraform plan -out=test.tfplan; then
    echo "✓ Terraform plan successful"
    rm -f test.tfplan
else
    echo "✗ Terraform plan failed"
    exit 1
fi

echo
echo "=== All Tests Passed! ==="
echo
echo "Your SCVMM Terraform configuration is ready to use."
echo
echo "To execute VM operations:"
echo "  terraform apply                    # Shutdown VM"
echo "  terraform apply -var='operation=start'   # Start VM"
echo "  terraform apply -var='operation=status'  # Check status"
echo

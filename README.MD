# Terraform Configuration for SCVMM Hyper-V VM Management

This Terraform configuration allows you to manage Hyper-V VMs through System Center Virtual Machine Manager (SCVMM) from Linux/Unix environments. It's designed for multi-host Hyper-V environments where VMs can be dynamically assigned to different host servers.

## Prerequisites

1. **PowerShell Core**: Install PowerShell Core on your Linux/Unix system
   ```bash
   # For Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install -y wget apt-transport-https software-properties-common
   wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
   sudo dpkg -i packages-microsoft-prod.deb
   sudo apt-get update
   sudo apt-get install -y powershell
   
   # For RHEL/CentOS
   sudo yum install -y powershell
   
   # For macOS
   brew install powershell
   ```

2. **SCVMM Access**: Ensure you have:
   - Network connectivity to your SCVMM server
   - Valid credentials with VM management permissions
   - SCVMM PowerShell module accessible from your SCVMM server

3. **Terraform**: Install Terraform on your system
   ```bash
   # Download and install Terraform
   wget https://releases.hashicorp.com/terraform/1.8.3/terraform_1.8.3_linux_amd64.zip
   unzip terraform_1.8.3_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

## Configuration

1. **Copy the example variables file**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars`** with your actual values:
   ```hcl
   scvmm_server   = "your-scvmm-server.domain.com"
   scvmm_username = "DOMAIN\\your-username"
   scvmm_password = "your-password"
   vm_name        = "your-vm-name"
   ```

## Quick Start

1. **Clone and setup**:
   ```bash
   cd terraform-hyperv-scvmm-linux
   make setup
   ```

2. **Configure your environment**:
   ```bash
   # Edit terraform.tfvars with your actual values
   nano terraform.tfvars
   ```

3. **Test connectivity**:
   ```bash
   make test
   ```

4. **Shutdown a VM**:
   ```bash
   make shutdown
   ```

## Usage

### Initialize Terraform
```bash
terraform init
```

### Turn Off a VM
```bash
terraform apply
```

### Check Plan Before Applying
```bash
terraform plan
```

### Destroy (Optional)
```bash
terraform destroy
```

## Using the Makefile

The project includes a comprehensive Makefile for easy operation:

```bash
# See all available commands
make help

# Setup and test
make setup
make test

# Single VM operations
make shutdown    # Shutdown VM
make start       # Start VM
make status      # Get VM status

# Multiple VM operations (requires terraform.tfvars.multi)
make multi-shutdown
make multi-start
make multi-status

# Manual script execution
make manual-shutdown
make manual-start
make manual-status
```

## Scripts

The configuration includes three utility scripts in the `scripts/` directory:

1. **`shutdown_vm.sh`**: Shuts down a VM via SCVMM
2. **`start_vm.sh`**: Starts a VM via SCVMM
3. **`get_vm_status.sh`**: Gets VM status and information

### Manual Script Usage

You can also run these scripts manually:

```bash
# Set environment variables
export SCVMM_SERVER="your-scvmm-server.domain.com"
export SCVMM_USERNAME="DOMAIN\\your-username"
export SCVMM_PASSWORD="your-password"
export VM_NAME="your-vm-name"

# Shutdown VM
./scripts/shutdown_vm.sh

# Start VM
./scripts/start_vm.sh

# Get VM status
./scripts/get_vm_status.sh
```

## Security Considerations

1. **Credentials**: Store sensitive credentials securely
   - Use environment variables instead of hardcoding
   - Consider using Terraform Cloud or HashiCorp Vault for secret management

2. **Network Security**: Ensure secure communication
   - Use VPN or secure network connections
   - Enable PowerShell remoting security features

## Features

- ✅ Multi-host Hyper-V environment support via SCVMM
- ✅ Linux/Unix execution environment
- ✅ VM shutdown with status monitoring
- ✅ VM startup capability
- ✅ VM status checking
- ✅ Error handling and timeout management
- ✅ Secure credential handling

## Troubleshooting

### Common Issues

1. **PowerShell Core not found**:
   - Ensure PowerShell Core is installed and in PATH
   - Verify installation: `pwsh --version`

2. **SCVMM connection issues**:
   - Check network connectivity to SCVMM server
   - Verify credentials and permissions
   - Ensure SCVMM PowerShell module is available

3. **VM not found**:
   - Verify VM name spelling and case sensitivity
   - Check if VM exists in SCVMM
   - Ensure user has access to the VM

4. **Timeout issues**:
   - Increase timeout values in scripts if needed
   - Check VM and host performance

## Advanced Configuration

For more complex scenarios, you can extend this configuration to:

- Manage multiple VMs simultaneously
- Configure VM settings (CPU, memory, etc.)
- Handle VM templates and deployment
- Integrate with monitoring systems

## License

This configuration is provided as-is for educational and operational purposes.
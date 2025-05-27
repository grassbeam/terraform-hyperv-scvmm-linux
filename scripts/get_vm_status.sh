#!/bin/bash

# Script to get VM status via SCVMM from Linux/Unix environment

set -e

# Check if required environment variables are set
if [[ -z "$SCVMM_SERVER" || -z "$SCVMM_USERNAME" || -z "$SCVMM_PASSWORD" || -z "$VM_NAME" ]]; then
    echo "Error: Required environment variables not set"
    echo "Required: SCVMM_SERVER, SCVMM_USERNAME, SCVMM_PASSWORD, VM_NAME"
    exit 1
fi

# Check if PowerShell Core is installed
if ! command -v pwsh &> /dev/null; then
    echo "Error: PowerShell Core (pwsh) is not installed"
    echo "Please install PowerShell Core: https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell"
    exit 1
fi

echo "Connecting to SCVMM server: $SCVMM_SERVER"
echo "Getting status for VM: $VM_NAME"

# Create PowerShell script content
POWERSHELL_SCRIPT=$(cat << 'EOF'
param(
    [string]$ScvmmServer,
    [string]$Username,
    [string]$Password,
    [string]$VmName
)

try {
    # Import SCVMM module
    Import-Module VirtualMachineManager -ErrorAction Stop
    
    # Create credential object
    $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)
    
    # Connect to SCVMM server
    Write-Host "Connecting to SCVMM server: $ScvmmServer"
    Get-SCVMMServer -ComputerName $ScvmmServer -Credential $Credential -ErrorAction Stop
    
    # Get the VM
    Write-Host "Looking for VM: $VmName"
    $VM = Get-SCVirtualMachine -Name $VmName -ErrorAction Stop
    
    if ($VM) {
        Write-Host "=== VM Information ==="
        Write-Host "Name: $($VM.Name)"
        Write-Host "Status: $($VM.Status)"
        Write-Host "Host: $($VM.HostName)"
        Write-Host "Operating System: $($VM.OperatingSystem)"
        Write-Host "CPU Count: $($VM.CPUCount)"
        Write-Host "Memory (MB): $($VM.Memory)"
        Write-Host "Creation Time: $($VM.CreationTime)"
        Write-Host "Modified Time: $($VM.ModifiedTime)"
        Write-Host "Cloud: $($VM.Cloud)"
        Write-Host "Owner: $($VM.Owner)"
        Write-Host "========================"
    } else {
        Write-Error "VM not found: $VmName"
        exit 1
    }
} catch {
    Write-Error "Error: $($_.Exception.Message)"
    exit 1
} finally {
    # Disconnect from SCVMM server
    if (Get-SCVMMServer -ErrorAction SilentlyContinue) {
        Write-Host "Disconnecting from SCVMM server"
        Get-SCVMMServer | Disconnect-SCVMMServer
    }
}
EOF
)

# Execute PowerShell script
echo "$POWERSHELL_SCRIPT" | pwsh -Command - -ScvmmServer "$SCVMM_SERVER" -Username "$SCVMM_USERNAME" -Password "$SCVMM_PASSWORD" -VmName "$VM_NAME"

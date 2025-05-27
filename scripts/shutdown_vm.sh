#!/bin/bash

# Script to shutdown VM via SCVMM from Linux/Unix environment
# This script uses PowerShell Core (pwsh) to execute SCVMM commands remotely

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
echo "Shutting down VM: $VM_NAME"

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
        Write-Host "VM found: $($VM.Name) on host: $($VM.HostName)"
        Write-Host "Current status: $($VM.Status)"
        
        # Check if VM is already stopped
        if ($VM.Status -eq "PowerOff") {
            Write-Host "VM is already powered off"
        } else {
            # Stop the VM
            Write-Host "Shutting down VM: $VmName"
            Stop-SCVirtualMachine -VM $VM -Shutdown -Force -ErrorAction Stop
            
            # Wait for shutdown to complete
            $timeout = 300 # 5 minutes timeout
            $elapsed = 0
            do {
                Start-Sleep -Seconds 10
                $elapsed += 10
                $VM = Get-SCVirtualMachine -Name $VmName
                Write-Host "VM Status: $($VM.Status) (elapsed: $elapsed seconds)"
            } while ($VM.Status -ne "PowerOff" -and $elapsed -lt $timeout)
            
            if ($VM.Status -eq "PowerOff") {
                Write-Host "VM successfully shut down"
            } else {
                Write-Warning "VM shutdown timeout reached. Current status: $($VM.Status)"
            }
        }
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

echo "VM shutdown operation completed"

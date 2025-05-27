#!/bin/bash

# Enhanced VM status script that outputs JSON for Terraform data source

set -e

# Read input from stdin (Terraform external data source passes query as JSON)
if [ -t 0 ]; then
    # Running manually, use environment variables
    if [[ -z "$SCVMM_SERVER" || -z "$SCVMM_USERNAME" || -z "$SCVMM_PASSWORD" || -z "$VM_NAME" ]]; then
        echo "Error: Required environment variables not set" >&2
        echo "Required: SCVMM_SERVER, SCVMM_USERNAME, SCVMM_PASSWORD, VM_NAME" >&2
        exit 1
    fi
else
    # Running from Terraform, parse JSON input
    eval "$(jq -r '@sh "SCVMM_SERVER=\(.scvmm_server) SCVMM_USERNAME=\(.scvmm_username) SCVMM_PASSWORD=\(.scvmm_password) VM_NAME=\(.vm_name)"')"
fi

# Check if PowerShell Core is installed
if ! command -v pwsh &> /dev/null; then
    echo '{"error": "PowerShell Core (pwsh) is not installed"}' >&2
    exit 1
fi

# Create PowerShell script content for JSON output
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
    Get-SCVMMServer -ComputerName $ScvmmServer -Credential $Credential -ErrorAction Stop | Out-Null
    
    # Get the VM
    $VM = Get-SCVirtualMachine -Name $VmName -ErrorAction Stop
    
    if ($VM) {
        # Create JSON output for Terraform
        $output = @{
            name = $VM.Name
            status = $VM.Status.ToString()
            host = $VM.HostName
            operating_system = $VM.OperatingSystem.ToString()
            cpu_count = $VM.CPUCount
            memory_mb = $VM.Memory
            creation_time = $VM.CreationTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
            owner = $VM.Owner
            cloud = if ($VM.Cloud) { $VM.Cloud.Name } else { "" }
            success = "true"
        }
        
        # Output JSON
        $output | ConvertTo-Json -Compress
    } else {
        Write-Output '{"error": "VM not found", "success": "false"}'
    }
} catch {
    $errorOutput = @{
        error = $_.Exception.Message
        success = "false"
    }
    $errorOutput | ConvertTo-Json -Compress
} finally {
    # Disconnect from SCVMM server
    if (Get-SCVMMServer -ErrorAction SilentlyContinue) {
        Get-SCVMMServer | Disconnect-SCVMMServer
    }
}
EOF
)

# Execute PowerShell script and capture output
OUTPUT=$(echo "$POWERSHELL_SCRIPT" | pwsh -Command - -ScvmmServer "$SCVMM_SERVER" -Username "$SCVMM_USERNAME" -Password "$SCVMM_PASSWORD" -VmName "$VM_NAME" 2>/dev/null)

# Output the JSON result
echo "$OUTPUT"

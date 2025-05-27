#!/bin/bash

# Installation script for PowerShell Core on various Linux distributions

set -e

echo "Installing PowerShell Core..."

# Detect the operating system
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif [[ -f /etc/redhat-release ]]; then
    OS="Red Hat Enterprise Linux"
    VER=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+')
elif [[ -f /etc/debian_version ]]; then
    OS="Debian"
    VER=$(cat /etc/debian_version)
else
    echo "Cannot detect operating system"
    exit 1
fi

echo "Detected OS: $OS $VER"

# Install PowerShell based on the detected OS
case "$OS" in
    "Ubuntu"*)
        echo "Installing PowerShell on Ubuntu..."
        sudo apt-get update
        sudo apt-get install -y wget apt-transport-https software-properties-common
        
        # Download the Microsoft repository GPG keys
        wget -q "https://packages.microsoft.com/config/ubuntu/$VER/packages-microsoft-prod.deb"
        sudo dpkg -i packages-microsoft-prod.deb
        
        # Update the list of packages and install PowerShell
        sudo apt-get update
        sudo apt-get install -y powershell
        ;;
        
    "Debian"*)
        echo "Installing PowerShell on Debian..."
        sudo apt-get update
        sudo apt-get install -y wget apt-transport-https software-properties-common
        
        # Download the Microsoft repository GPG keys
        wget -q "https://packages.microsoft.com/config/debian/$VER/packages-microsoft-prod.deb"
        sudo dpkg -i packages-microsoft-prod.deb
        
        # Update the list of packages and install PowerShell
        sudo apt-get update
        sudo apt-get install -y powershell
        ;;
        
    "CentOS Linux"*|"Red Hat Enterprise Linux"*)
        echo "Installing PowerShell on RHEL/CentOS..."
        
        # Register the Microsoft RedHat repository
        curl https://packages.microsoft.com/config/rhel/8/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo
        
        # Install PowerShell
        sudo yum install -y powershell
        ;;
        
    "Fedora"*)
        echo "Installing PowerShell on Fedora..."
        
        # Register the Microsoft signature key
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        
        # Register the Microsoft RedHat repository
        curl https://packages.microsoft.com/config/rhel/8/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo
        
        # Install PowerShell
        sudo dnf install -y powershell
        ;;
        
    "SUSE Linux Enterprise Server"*|"openSUSE"*)
        echo "Installing PowerShell on SUSE..."
        
        # Register the Microsoft signature key
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        
        # Add the Microsoft repository
        curl https://packages.microsoft.com/config/rhel/8/prod.repo | sudo tee /etc/zypp/repos.d/microsoft.repo
        
        # Install PowerShell
        sudo zypper install -y powershell
        ;;
        
    *)
        echo "Unsupported OS: $OS"
        echo "Please install PowerShell Core manually from:"
        echo "https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell"
        exit 1
        ;;
esac

# Verify installation
if command -v pwsh &> /dev/null; then
    echo "PowerShell Core installed successfully!"
    pwsh --version
else
    echo "PowerShell Core installation failed!"
    exit 1
fi

echo "Installation complete!"

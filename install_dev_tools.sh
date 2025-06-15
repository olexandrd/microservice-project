#!/bin/bash
# This script installs development tools including Docker, 
# Docker Compose, Python3, pip and django on a Debian-based system.

# Skip interactive prompts during package installation
export DEBIAN_FRONTEND=noninteractive

# It checks if the user is root and if the apt package manager is available.
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Use 'sudo' to run it."
    exit 1
fi
if which apt >/dev/null 2>&1; then
    echo "Using apt package manager."
else
    echo "This script is designed for systems using apt package manager."
    exit 1
fi

# Update the package list and install required packages
PACKAGES="docker.io \
        docker-compose \
        python3 \
        python3-pip \
        python3-venv"
apt update
for package in $PACKAGES; do
    if ! dpkg -l | grep -q "^ii\s\+$package\s"; then
        echo "Installing $package..."
        apt install -q -y --no-install-recommends $package
    else
        echo "$package is already installed."
    fi
done

# Make directory for the application
mkdir -p /app && \
    cd /app 

# Create a virtual environment in the current directory
if [ ! -f ".venv/pyvenv.cfg" -o ! -f ".venv/bin/activate" ]; then
    python3 -m venv .venv
    echo "Virtual environment created at /app/.venv"
else
    echo "Virtual environment already exists at /app/.venv"
fi

# Activate the virtual environment and install Django
source .venv/bin/activate && \
    # Upgrade pip to the latest version
    pip3 install --upgrade pip
    # Install Django if not already installed 
    if ! pip3 list 2>/dev/null | grep -q Django; then
        pip3 install Django
        echo "Django installed successfully."
    else
        echo "Django is already installed."
    fi
deactivate

echo "Development tools installed successfully to /app"

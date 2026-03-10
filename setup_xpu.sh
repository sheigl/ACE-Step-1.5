#!/usr/bin/env bash
# ACE-Step XPU Environment Setup Script for Linux
# This script creates the venv_xpu virtual environment and installs all dependencies
# for Intel Arc GPUs (A770, A750, A580, A380) and integrated graphics

set -euo pipefail

echo "======================================================"
echo "     ACE-Step 1.5 - Intel XPU Environment Setup"
echo "======================================================"
echo
echo "This script will:"
echo "  1. Create venv_xpu virtual environment (Python 3.11)"
echo "  2. Install PyTorch XPU nightly build"
echo "  3. Install all ACE-Step dependencies"
echo
echo "Requirements:"
echo "  - Python 3.11 installed and in PATH"
echo "  - Intel Arc GPU with latest drivers"
echo "  - Internet connection for first-time installation"
echo "  - ~5-10 GB disk space"
echo

# Check Python version
if ! command -v python3.11 &>/dev/null; then
    echo "========================================"
    echo " ERROR: Python 3.11 not found!"
    echo "========================================"
    echo
    echo "Please install Python 3.11 and ensure it's in your PATH."
    echo "For Ubuntu/Debian: sudo apt install python3.11"
    echo "For CentOS/RHEL/Fedora: sudo dnf install python3.11"
    echo
    read -rp "Press any key to continue or Ctrl+C to cancel..."
    echo
else
    echo "Python 3.11 found: $(python3.11 --version)"
    echo
fi

# Check if venv_xpu already exists
if [[ -d "venv_xpu" ]]; then
    echo "========================================"
    echo " venv_xpu already exists!"
    echo "========================================"
    echo
    echo "Location: $(pwd)/venv_xpu"
    echo
    read -rp "Recreate virtual environment? (Y/N): " RECREATE
    echo
    if [[ "${RECREATE^^}" == "Y" ]]; then
        echo "Removing old venv_xpu..."
        rm -rf venv_xpu
        echo
    else
        echo "Existing environment will be updated."
        echo
    fi
fi

# Create virtual environment
echo "========================================"
echo "Step 1: Creating virtual environment"
echo "========================================"
echo

if [[ -d "venv_xpu" ]]; then
    echo "Cleaning existing venv_xpu..."
    rm -rf venv_xpu
fi

echo "Running: python3.11 -m venv venv_xpu"
echo
python3.11 -m venv venv_xpu

if [[ $? -ne 0 ]]; then
    echo
    echo "========================================"
    echo " ERROR: Failed to create virtual environment!"
    echo "========================================"
    echo
    echo "Please check:"
    echo "  1. Python 3.11 is installed correctly"
    echo "  2. You have write permissions in this directory"
    echo "  3. No antivirus is blocking venv creation"
    echo
    read -rp "Press any key to continue..."
    exit 1
fi

echo "Virtual environment created successfully!"
echo

# Activate virtual environment
echo "========================================"
echo "Step 2: Activating virtual environment"
echo "========================================"
echo

# Source the activate script
source venv_xpu/bin/activate

# Upgrade pip
echo "========================================"
echo "Step 3: Upgrading pip"
echo "========================================"
echo

echo "Running: pip install --upgrade pip"
pip install --upgrade pip

echo "pip upgraded successfully!"
echo

# Check requirements-xpu.txt exists
if [[ ! -f "requirements-xpu.txt" ]]; then
    echo "========================================"
    echo " ERROR: requirements-xpu.txt not found!"
    echo "========================================"
    echo
    echo "Please make sure you are running this script"
    echo "from the ACE-Step-1.5 root directory."
    echo
    read -rp "Press any key to continue..."
    exit 1
fi

# Install dependencies
echo "========================================"
echo "Step 4: Installing XPU dependencies"
echo "========================================"
echo
echo "This will take a few minutes on first run..."
echo

echo "Running: pip install -r requirements-xpu.txt"
echo

pip install -r requirements-xpu.txt

if [[ $? -ne 0 ]]; then
    echo
    echo "========================================"
    echo " WARNING: Some packages may have failed to install"
    echo "========================================"
    echo
    echo "This can happen due to:"
    echo "  - Network issues"
    echo "  - Incompatible package versions"
    echo
    echo "Trying to continue with available packages..."
    echo
    sleep 5
fi

echo
echo "========================================"
echo "Step 5: Verifying Installation"
echo "========================================"
echo

# Verify PyTorch XPU installation
echo "Checking PyTorch XPU installation..."
python -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'XPU available: {torch.xpu.is_available()}')"

if [[ $? -ne 0 ]]; then
    echo
    echo "WARNING: PyTorch XPU verification failed!"
    echo "The installation may be incomplete."
    echo
    echo "Try running manually:"
    echo "  source venv_xpu/bin/activate"
    echo "  pip install -r requirements-xpu.txt"
    echo
else
    echo "PyTorch XPU installed successfully!"
fi
echo

# Display summary
echo "======================================================"
echo "     Installation Complete!"
echo "======================================================"
echo
echo "Your ACE-Step XPU environment is ready to use!"
echo
echo "Next steps:"
echo "  1. Download ACE-Step models to the 'checkpoints' folder"
echo "     (if not already present)"
echo
echo "  2. Launch the Gradio UI:"
echo "     ./start_gradio_ui_xpu.sh"
echo
echo "  3. Or launch with manual model selection:"
echo "     ./start_gradio_ui_xpu_manual.sh"
echo
echo "  4. Or launch the API server:"
echo "     ./start_api_server_xpu.sh"
echo
echo "To activate the environment manually:"
echo "  source venv_xpu/bin/activate"
echo
echo "======================================================"
echo
read -rp "Press any key to continue..."

exit 0
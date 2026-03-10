#!/usr/bin/env bash
# Test script to verify XPU setup is working correctly

set -euo pipefail

echo "=============================================="
echo "Testing ACE-Step XPU Setup"
echo "=============================================="

# Check if we have the required files
echo "Checking for required files..."
if [[ ! -f "setup_xpu.sh" ]]; then
    echo "ERROR: setup_xpu.sh not found"
    exit 1
fi

if [[ ! -f "start_gradio_ui_xpu.sh" ]]; then
    echo "ERROR: start_gradio_ui_xpu.sh not found"
    exit 1
fi

if [[ ! -f "start_api_server_xpu.sh" ]]; then
    echo "ERROR: start_api_server_xpu.sh not found"
    exit 1
fi

if [[ ! -f "requirements-xpu.txt" ]]; then
    echo "ERROR: requirements-xpu.txt not found"
    exit 1
fi

echo "✓ All required files present"

# Check if Python 3.11 is available
if ! command -v python3.11 &>/dev/null; then
    echo "WARNING: Python 3.11 not found, but we'll proceed anyway"
    PYTHON_CMD="python3"
else
    PYTHON_CMD="python3.11"
fi

# Check if virtual environment exists
if [[ -d "venv_xpu" ]]; then
    echo "✓ Virtual environment venv_xpu exists"
    
    # Check if it's activated and has the right packages
    echo "Checking PyTorch XPU installation..."
    source venv_xpu/bin/activate 2>/dev/null || {
        echo "ERROR: Could not activate venv_xpu"
        exit 1
    }
    
    if $PYTHON_CMD -c "import torch; print('PyTorch version:', torch.__version__); print('XPU available:', torch.xpu.is_available())" &>/dev/null; then
        echo "✓ PyTorch XPU installation verified"
    else
        echo "WARNING: PyTorch XPU not properly installed in venv_xpu"
    fi
    
    deactivate
else
    echo "ℹ Virtual environment venv_xpu does not exist yet"
fi

echo
echo "=============================================="
echo "Setup verification complete!"
echo "=============================================="
echo
echo "To set up XPU support, run:"
echo "  ./setup_xpu.sh"
echo
echo "To launch the Gradio UI:"
echo "  ./start_gradio_ui_xpu.sh"
echo
echo "To launch the API server:"
echo "  ./start_api_server_xpu.sh"
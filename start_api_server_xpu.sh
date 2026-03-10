#!/usr/bin/env bash
# ACE-Step API Server Launcher - Intel XPU
# For Intel Arc GPUs (A770, A750, A580, A380) and integrated graphics
# Requires: Python 3.11, PyTorch XPU nightly from download.pytorch.org/whl/xpu

set -euo pipefail

# ==================== Load .env Configuration ====================
# Load settings from .env file if it exists
load_env_file() {
    local env_file="${SCRIPT_DIR}/.env"
    if [[ ! -f "$env_file" ]]; then
        return 0
    fi
    
    echo "[Config] Loading configuration from .env file..."
    
    # Read .env file and export variables
    while IFS='=' read -r key value || [[ -n "$key" ]]; do
        # Skip empty lines and comments
        [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
        
        # Trim whitespace from key and value
        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"
        
        # Map .env variable names to script variables
        case "$key" in
            ACESTEP_CONFIG_PATH)
                [[ -n "$value" ]] && CONFIG_PATH="--config_path $value"
                ;;
            ACESTEP_LM_MODEL_PATH)
                [[ -n "$value" ]] && LM_MODEL_PATH="--lm_model_path $value"
                ;;
            ACESTEP_INIT_LLM)
                if [[ -n "$value" && "$value" != "auto" ]]; then
                    INIT_LLM="--init_llm $value"
                fi
                ;;
            ACESTEP_DOWNLOAD_SOURCE)
                if [[ -n "$value" && "$value" != "auto" ]]; then
                    DOWNLOAD_SOURCE="--download-source $value"
                fi
                ;;
            ACESTEP_API_KEY)
                [[ -n "$value" ]] && API_KEY="--api-key $value"
                ;;
            PORT)
                [[ -n "$value" ]] && PORT="$value"
                ;;
            SERVER_NAME)
                [[ -n "$value" ]] && SERVER_NAME="$value"
                ;;
            LANGUAGE)
                [[ -n "$value" ]] && LANGUAGE="$value"
                ;;
            ACESTEP_BATCH_SIZE)
                [[ -n "$value" ]] && BATCH_SIZE="--batch_size $value"
                ;;
            ACESTEP_OFFLOAD_TO_CPU)
                [[ -n "$value" ]] && OFFLOAD_TO_CPU="--offload_to_cpu $value"
                ;;
        esac
    done < "$env_file"
    
    echo "[Config] Configuration loaded from .env"
}

# ==================== XPU Configuration ====================
# XPU performance optimization (from verified working setup)
export SYCL_CACHE_PERSISTENT=1
export SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS=1
export PYTORCH_DEVICE=xpu

# Disable torch.compile (not fully supported on XPU yet)
export TORCH_COMPILE_BACKEND=eager

# HuggingFace tokenizer parallelism
export TOKENIZERS_PARALLELISM=false

# Force torchaudio to use ffmpeg backend (torchcodec not available on XPU)
export TORCHAUDIO_USE_BACKEND=ffmpeg

# ==================== Server Configuration ====================
# Default values (used if not set in .env file)
# You can override these by uncommenting and modifying the lines below
# or by creating a .env file (recommended to survive updates)

: "${PORT:=7860}"
: "${SERVER_NAME:=127.0.0.1}"
# SERVER_NAME="0.0.0.0"
# SHARE="--share"

# UI language: en, zh, ja
: "${LANGUAGE:=en}"

# Batch size: default batch size for generation (1 to GPU-dependent max)
# When not specified, defaults to min(2, GPU_max)
# BATCH_SIZE="--batch_size 4"

# ==================== Model Configuration ====================
# Default model (can be overridden in .env file)
: "${CONFIG_PATH:=--config_path acestep-v15-turbo}"
: "${LM_MODEL_PATH:=--lm_model_path acestep-5Hz-lm-4B}"

# CPU offload: recommended for 4B LM on GPUs with <=16GB VRAM
# Models shuttle between CPU/GPU as needed (DiT stays on GPU, LM/VAE/text_encoder move on demand)
# Adds ~8-10s overhead per generation but prevents VRAM oversubscription
# Disable if using 1.7B/0.6B LM or if your GPU has >=20GB VRAM
: "${OFFLOAD_TO_CPU:=--offload_to_cpu true}"

# LLM initialization: auto (default), true, false
# INIT_LLM="--init_llm auto"

# Download source: auto, huggingface, modelscope
# DOWNLOAD_SOURCE=""

# Auto-initialize models on startup
: "${INIT_SERVICE:=--init_service true}"

# API settings
: "${ENABLE_API:=--enable-api}"
# API_KEY="--api-key sk-your-secret-key"

# Authentication
# AUTH_USERNAME="--auth-username admin"
# AUTH_PASSWORD="--auth-password password"

# Update check on startup (set to "false" to disable)
: "${CHECK_UPDATE:=true}"
# CHECK_UPDATE="false"

# ==================== Venv Configuration ====================
# Path to the XPU virtual environment (relative to this script)
VENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/venv_xpu"

# ==================== Launch ====================

# ==================== Startup Update Check ====================
if [[ "${CHECK_UPDATE,,}" != "true" ]]; then
    SKIP_UPDATE_CHECK=true
else
    SKIP_UPDATE_CHECK=false
fi

if [[ "$SKIP_UPDATE_CHECK" == false ]]; then
    # Check if git is available
    if ! command -v git &>/dev/null; then
        echo "[Update] Git not found, skipping update check."
        echo
        SKIP_UPDATE_CHECK=true
    fi
    
    if [[ "$SKIP_UPDATE_CHECK" == false ]]; then
        cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1
        git rev-parse --git-dir &>/dev/null 2>&1 || {
            echo "[Update] Not in a git repository, skipping update check."
            echo
            SKIP_UPDATE_CHECK=true
        }
    fi
    
    if [[ "$SKIP_UPDATE_CHECK" == false ]]; then
        echo "[Update] Checking for updates..."
        
        # Fetch with timeout (10s)
        local fetch_ok=0
        if command -v timeout &>/dev/null; then
            timeout 10 git fetch origin --quiet 2>/dev/null && fetch_ok=1
        elif command -v gtimeout &>/dev/null; then
            gtimeout 10 git fetch origin --quiet 2>/dev/null && fetch_ok=1
        else
            git fetch origin --quiet 2>/dev/null && fetch_ok=1
        fi
        
        if [[ $fetch_ok -eq 0 ]]; then
            echo "[Update] Network unreachable, skipping."
            echo
            SKIP_UPDATE_CHECK=true
        fi
        
        if [[ "$SKIP_UPDATE_CHECK" == false ]]; then
            local branch commit remote_commit
            branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")"
            commit="$(git rev-parse --short HEAD 2>/dev/null || echo "")"
            
            if [[ -z "$commit" ]]; then
                echo "[Update] Could not determine current commit, skipping update check."
                echo
                SKIP_UPDATE_CHECK=true
            fi
            
            if [[ "$SKIP_UPDATE_CHECK" == false ]]; then
                remote_commit="$(git rev-parse --short "origin/$branch" 2>/dev/null || echo "")"
                
                if [[ -z "$remote_commit" ]]; then
                    echo "[Update] Could not determine remote commit, skipping update check."
                    echo
                    SKIP_UPDATE_CHECK=true
                fi
                
                if [[ "$SKIP_UPDATE_CHECK" == false && "$commit" == "$remote_commit" ]]; then
                    echo "[Update] Already up to date ($commit)."
                    echo
                    SKIP_UPDATE_CHECK=true
                fi
            fi
        fi
    fi
    
    if [[ "$SKIP_UPDATE_CHECK" == false ]]; then
        echo
        echo "========================================"
        echo "  Update available!"
        echo "========================================"
        echo "  Current: $commit  ->  Latest: $remote_commit"
        echo
        echo "  Recent changes:"
        git --no-pager log --oneline "HEAD..origin/$branch" 2>/dev/null | head -10
        echo
        
        read -rp "Update now before starting? (Y/N): " update_choice
        if [[ "${update_choice,,}" == "y" ]]; then
            if [[ -f "$SCRIPT_DIR/check_update.sh" ]]; then
                bash "$SCRIPT_DIR/check_update.sh"
            else
                echo "Pulling latest changes..."
                git pull --ff-only origin "$branch" 2>/dev/null || {
                    echo "[Update] Update failed. Please run: git pull"
                }
            fi
        else
            echo "[Update] Skipped. Run ./check_update.sh to update later."
        fi
        echo
    fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load .env configuration
load_env_file

echo "============================================"
echo "   ACE-Step 1.5 - Intel XPU API Server"
echo "============================================"
echo

# Activate venv if it exists
if [[ -d "$VENV_DIR" ]]; then
    echo "Activating XPU virtual environment: $VENV_DIR"
    source "$VENV_DIR/bin/activate"
else
    echo "========================================"
    echo " ERROR: venv_xpu not found!"
    echo "========================================"
    echo
    echo "Please create the XPU virtual environment first:"
    echo
    echo "  1. Run: python3.11 -m venv venv_xpu"
    echo "  2. Run: source venv_xpu/bin/activate"
    echo "  3. Run: pip install -r requirements-xpu.txt"
    echo
    echo "Or use the setup script (if available)"
    echo "  ./setup_xpu.sh"
    echo
    read -rp "Press any key to continue..."
    exit 1
fi
echo

# Verify XPU PyTorch is installed
python -c "import torch; assert hasattr(torch, 'xpu') and torch.xpu.is_available(), 'Intel XPU not detected'; print(f'XPU: Intel Arc GPU detected'); print(f'PyTorch XPU version: {torch.__version__}')"

if [[ $? -ne 0 ]]; then
    echo
    echo "========================================"
    echo " ERROR: Intel XPU PyTorch not detected!"
    echo "========================================"
    echo
    echo "Please install PyTorch with XPU support. See requirements-xpu.txt for instructions."
    echo
    echo "Quick setup:"
    echo "  1. Activate venv: source venv_xpu/bin/activate"
    echo "  2. Install: pip install --upgrade pip"
    echo "  3. Install XPyTorch: pip install -r requirements-xpu.txt"
    echo
    read -rp "Press any key to continue..."
    exit 1
fi
echo

echo "Starting ACE-Step API Server..."
echo "API will be available at: http://${SERVER_NAME}:${PORT}"
echo "Default Model: acestep-v15-turbo"
echo "LM Model: acestep-5Hz-lm-4B (with CPU offload)"
echo
echo "API Endpoints:"
echo "  POST /generate - Generate music"
echo "  GET /health - Health check"
echo "  GET /docs - API documentation"
echo

# Build command with optional parameters
ACESTEP_ARGS="acestep --port $PORT --server-name $SERVER_NAME --language $LANGUAGE --enable-api"
[[ -n "$SHARE" ]] && ACESTEP_ARGS="$ACESTEP_ARGS $SHARE"
[[ -n "$CONFIG_PATH" ]] && ACESTEP_ARGS="$ACESTEP_ARGS $CONFIG_PATH"
[[ -n "$LM_MODEL_PATH" ]] && ACESTEP_ARGS="$ACESTEP_ARGS $LM_MODEL_PATH"
[[ -n "$OFFLOAD_TO_CPU" ]] && ACESTEP_ARGS="$ACESTEP_ARGS $OFFLOAD_TO_CPU"
[[ -n "$INIT_LLM" ]] && ACESTEP_ARGS="$ACESTEP_ARGS $INIT_LLM"
[[ -n "$DOWNLOAD_SOURCE" ]] && ACESTEP_ARGS="$ACESTEP_ARGS $DOWNLOAD_SOURCE"
[[ -n "$INIT_SERVICE" ]] && ACESTEP_ARGS="$ACESTEP_ARGS $INIT_SERVICE"
[[ -n "$BATCH_SIZE" ]] && ACESTEP_ARGS="$ACESTEP_ARGS $BATCH_SIZE"
[[ -n "$API_KEY" ]] && ACESTEP_ARGS="$ACESTEP_ARGS $API_KEY"
[[ -n "$AUTH_USERNAME" ]] && ACESTEP_ARGS="$ACESTEP_ARGS $AUTH_USERNAME"
[[ -n "$AUTH_PASSWORD" ]] && ACESTEP_ARGS="$ACESTEP_ARGS $AUTH_PASSWORD"

cd "$SCRIPT_DIR" && python -u acestep/acestep_v15_pipeline.py $ACESTEP_ARGS

read -rp "Press any key to exit..."
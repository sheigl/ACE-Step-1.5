# ACE-Step 1.5 - Linux XPU Setup Guide

This guide explains how to run ACE-Step on Linux with Intel XPU support (Intel Arc GPUs and integrated graphics).

## 🎯 Requirements

- **Intel Arc GPU**: A770, A750, A580, A380, or Intel integrated graphics
- **Python 3.11**: Install from your distribution's package manager or python.org
- **Latest Intel GPU drivers**: Install from Intel's website
- **Internet connection**: For first-time setup
- **Disk space**: ~5-10 GB for dependencies

## 🚀 Quick Start

### Option 1: Automatic Setup (Recommended)

1. **Run the setup script**:
   ```bash
   ./setup_xpu.sh
   ```

2. **Wait for installation** (takes a few minutes on first run)

3. **Launch the Gradio UI**:
   ```bash
   ./start_gradio_ui_xpu.sh
   ```

4. **Open your browser**: http://127.0.0.1:7860

### Option 2: Manual Setup

1. **Create virtual environment**:
   ```bash
   python3.11 -m venv venv_xpu
   ```

2. **Activate it**:
   ```bash
   source venv_xpu/bin/activate
   ```

3. **Upgrade pip**:
   ```bash
   python -m pip install --upgrade pip
   ```

4. **Install XPU dependencies**:
   ```bash
   pip install -r requirements-xpu.txt
   ```

5. **Launch**:
   ```bash
   ./start_gradio_ui_xpu.sh
   ```

## 📁 Model Configuration

Models should be placed in the `checkpoints` folder. If you already have models from a previous installation, they will be automatically detected.

### Default Models
- **DiT Model**: `acestep-v15-turbo` (fast generation)
- **LM Model**: `acestep-5Hz-lm-4B` (best quality, uses CPU offload)

### Launch Options

1. **Automatic** (uses defaults):
   ```bash
   ./start_gradio_ui_xpu.sh
   ```

2. **Manual** (choose models interactively):
   ```bash
   ./start_gradio_ui_xpu_manual.sh
   ```

3. **API Server** (REST API access):
   ```bash
   ./start_api_server_xpu.sh
   ```

## ⚙️ XPU Environment Variables

The scripts automatically set these performance optimizations:

```bash
export SYCL_CACHE_PERSISTENT=1
export SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS=1
export PYTORCH_DEVICE=xpu
export TORCH_COMPILE_BACKEND=eager
```

These settings improve XPU performance and are based on verified working configurations.

## 🔧 Configuration (.env file)

Create a `.env` file in the root directory to customize settings:

```env
# Gradio UI Settings
PORT=7860
SERVER_NAME=127.0.0.1
LANGUAGE=en

# Model Settings
ACESTEP_CONFIG_PATH=acestep-v15-turbo
ACESTEP_LM_MODEL_PATH=acestep-5Hz-lm-4B
ACESTEP_OFFLOAD_TO_CPU=true

# API Settings
ACESTEP_API_KEY=your-secret-key
```

## 🛠️ Troubleshooting

### "venv_xpu not found"
Run `./setup_xpu.sh` to create the virtual environment.

### "Intel XPU not detected"
1. Check that your GPU drivers are up to date
2. Verify PyTorch XPU installation:
   ```bash
   source venv_xpu/bin/activate
   python -c "import torch; print(torch.xpu.is_available())"
   ```

### "torch.xpu.is_available() returns False"
Reinstall PyTorch XPU:
```bash
source venv_xpu/bin/activate
pip uninstall torch torchaudio torchvision
pip install --pre torch torchaudio torchvision --index-url https://download.pytorch.org/whl/nightly/xpu
```

### Out of memory errors
1. Use a smaller LM model (0.6B or 1.7B instead of 4B)
2. Enable CPU offload in the UI
3. Close other GPU-intensive applications

### Audio loading issues
- MP3/Opus/AAC files use torchaudio with ffmpeg backend (bundled)
- FLAC/WAV files use soundfile (fastest)
- If issues occur, try converting to WAV format

## 📊 Launch Scripts

| Script | Description |
|--------|-------------|
| `setup_xpu.sh` | One-command environment setup |
| `start_gradio_ui_xpu.sh` | Launch Gradio web UI (automatic) |
| `start_gradio_ui_xpu_manual.sh` | Launch Gradio UI with model selection |
| `start_api_server_xpu.sh` | Launch REST API server |

## 🎵 Audio Support

- ✅ **WAV/FLAC**: Native support via soundfile (fastest)
- ✅ **MP3**: Supported via torchaudio with ffmpeg backend
- ✅ **Opus/AAC**: Supported via torchaudio

No additional codec installation needed!

## 📝 Notes

1. **First launch** takes longer as models are initialized
2. **CPU offload** is recommended for 4B LM on GPUs with <=16GB VRAM
3. **torch.compile** is disabled (not fully supported on XPU yet)
4. **Python 3.11** is recommended for best compatibility

## 🆘 Need Help?

- Check the main documentation: `README.md`
- Verify XPU installation: Run verification commands above
- Update check: Scripts automatically check for updates on startup

## 🎉 You're Ready!

Once setup is complete, simply run:
```bash
./start_gradio_ui_xpu.sh
```

And start creating music with ACE-Step on your Intel GPU!
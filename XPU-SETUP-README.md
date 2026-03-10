# Linux XPU Support for ACE-Step 1.5

## Summary

This project adds full Linux support for Intel XPU (Arc GPUs and integrated graphics) to the ACE-Step 1.5 repository, which previously only had Windows support.

## What Was Added

1. **setup_xpu.sh** - Linux equivalent of the Windows setup_xpu.bat script
   - Creates venv_xpu virtual environment
   - Installs PyTorch XPU nightly build
   - Installs all ACE-Step dependencies for XPU

2. **start_gradio_ui_xpu.sh** - Linux equivalent of the Windows start_gradio_ui_xpu.bat script
   - Launches the Gradio web UI with XPU optimizations
   - Sets required environment variables for XPU performance
   - Supports automatic model selection

3. **start_gradio_ui_xpu_manual.sh** - Linux equivalent of the Windows start_gradio_ui_xpu_manual.bat script
   - Launches the Gradio web UI with interactive model selection
   - Allows users to choose models at runtime

4. **start_api_server_xpu.sh** - Linux equivalent of the Windows start_api_server_xpu.bat script
   - Launches the REST API server with XPU support
   - Enables API access to the ACE-Step functionality

5. **README-LINUX-XPU.md** - Comprehensive documentation for Linux XPU setup

6. **.env.example.xpu** - Example .env configuration for XPU setup

## How to Use

1. **Setup XPU environment**:
   ```bash
   ./setup_xpu.sh
   ```

2. **Launch Gradio UI**:
   ```bash
   ./start_gradio_ui_xpu.sh
   ```

3. **Launch Gradio UI with manual model selection**:
   ```bash
   ./start_gradio_ui_xpu_manual.sh
   ```

4. **Launch API server**:
   ```bash
   ./start_api_server_xpu.sh
   ```

## Key Features

- **Full XPU Optimization**: Sets all required environment variables for optimal performance
- **Cross-platform Compatibility**: Same functionality as Windows version
- **Automatic Updates**: Checks for updates on startup like the original scripts
- **Environment Management**: Proper virtual environment handling for XPU dependencies
- **Configuration Support**: Full .env file support for customization

## Requirements

- Python 3.11
- Intel Arc GPU with latest drivers
- Internet connection for first-time setup
- ~5-10 GB disk space

## Notes

The scripts have been carefully adapted from the Windows batch files to work on Linux, maintaining the same functionality and performance optimizations. The XPU support leverages PyTorch's nightly builds from download.pytorch.org/whl/xpu.
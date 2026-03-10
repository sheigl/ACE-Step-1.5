# Containerizing ACE-Step 1.5 with Intel XPU Support

This document explains how to containerize the ACE-Step 1.5 application with Intel XPU support using Docker.

## Docker Setup

### Available Dockerfiles

1. **Dockerfile.xpu** - Basic Dockerfile with all dependencies
2. **Dockerfile.xpu.optimized** - Optimized version with better layering
3. **Dockerfile.xpu.complete** - Multi-stage build for minimal image size

### Building the Container

```bash
# Build the optimized version
docker build -f Dockerfile.xpu.complete -t acestep-xpu .

# Or build with a custom tag
docker build -f Dockerfile.xpu.complete -t my-acestep-xpu .
```

### Running the Container

#### Basic Usage
```bash
# Run with default settings
docker run --rm -it --device=/dev/dri:/dev/dri -p 7860:7860 acestep-xpu
```

#### With Persistent Storage
```bash
# Mount checkpoints directory for model persistence
docker run --rm -it --device=/dev/dri:/dev/dri -p 7860:7860 -v $(pwd)/checkpoints:/app/checkpoints acestep-xpu
```

#### Development Mode
```bash
# Run with shell access for debugging
docker run --rm -it --device=/dev/dri:/dev/dri -p 7860:7860 -v $(pwd):/app acestep-xpu /bin/bash
```

### Docker Compose Usage

```bash
# Use docker-compose.xpu.yml for easy deployment
docker-compose -f docker-compose.xpu.yml up -d

# To stop
docker-compose -f docker-compose.xpu.yml down
```

## Environment Variables

The container supports the following environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| PORT | 7860 | Port for the Gradio UI |
| SERVER_NAME | 127.0.0.1 | Server name for the UI |
| LANGUAGE | en | UI language |
| ACESTEP_CONFIG_PATH | acestep-v15-turbo | DiT model to use |
| ACESTEP_LM_MODEL_PATH | acestep-5Hz-lm-4B | Language model to use |
| ACESTEP_OFFLOAD_TO_CPU | true | Enable CPU offloading |

## Required Hardware Access

For XPU support, the container needs access to the Intel GPU devices:

```bash
# Required device mapping
--device=/dev/dri:/dev/dri
```

## Volume Mounts

| Host Path | Container Path | Description |
|-----------|----------------|-------------|
| ./checkpoints | /app/checkpoints | Model storage |
| ./logs | /app/logs | Log files |

## Docker Compose Example

```yaml
version: '3.8'
services:
  acestep-xpu:
    build:
      context: .
      dockerfile: Dockerfile.xpu.complete
    container_name: acestep-xpu
    ports:
      - "7860:7860"
    volumes:
      - ./checkpoints:/app/checkpoints
      - ./logs:/app/logs
    environment:
      - PORT=7860
      - SERVER_NAME=0.0.0.0
      - LANGUAGE=en
      - ACESTEP_CONFIG_PATH=acestep-v15-turbo
      - ACESTEP_LM_MODEL_PATH=acestep-5Hz-lm-4B
      - ACESTEP_OFFLOAD_TO_CPU=true
    devices:
      - "/dev/dri:/dev/dri"
    stdin_open: true
    tty: true
    restart: unless-stopped
```

## Troubleshooting

### XPU Not Detected
If the container reports XPU not detected, ensure:
1. The host system has Intel GPU drivers installed
2. The container has proper device access (`--device=/dev/dri:/dev/dri`)
3. The XPU PyTorch package is properly installed in the container

### Port Conflicts
If port 7860 is in use:
```bash
# Change to a different port
docker run --rm -it --device=/dev/dri:/dev/dri -p 8080:7860 acestep-xpu
```

### Permission Issues
If you encounter permission issues with volume mounts:
```bash
# Fix permissions on host directories
sudo chown -R $(id -u):$(id -g) checkpoints logs
```

## Notes

1. **First Run**: The initial container run will download and install all dependencies, which may take several minutes.

2. **Model Storage**: Mount the checkpoints directory to persist models between container runs.

3. **XPU Requirements**: The host system must have Intel GPU drivers and the appropriate software stack installed.

4. **Resource Usage**: XPU acceleration requires proper GPU memory management; ensure sufficient VRAM for your models.

## Build Script

A convenience script `docker-xpu-build.sh` is provided to simplify the build process:

```bash
./docker-xpu-build.sh
```
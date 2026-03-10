#!/bin/bash

# Build and run ACE-Step XPU Docker container

echo "Building ACE-Step XPU Docker image..."
docker build -f Dockerfile.xpu.complete -t acestep-xpu .

echo "Docker image built successfully!"

echo "To run the container with XPU support:"
echo "docker run --rm -it --device=/dev/dri:/dev/dri -p 7860:7860 acestep-xpu"

echo "For persistent storage:"
echo "docker run --rm -it --device=/dev/dri:/dev/dri -p 7860:7860 -v \$(pwd)/checkpoints:/app/checkpoints acestep-xpu"

echo "For development mode:"
echo "docker run --rm -it --device=/dev/dri:/dev/dri -p 7860:7860 -v \$(pwd):/app acestep-xpu /bin/bash"
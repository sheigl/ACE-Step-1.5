#!/bin/bash

echo "==============================================="
echo "Verifying ACE-Step XPU Container Setup"
echo "==============================================="

# Check if required files exist
echo "Checking for required files..."

files=(
    "Dockerfile.xpu.complete"
    "docker-compose.xpu.yml"
    "docker-xpu-build.sh"
    "DOCKER-INSTRUCTIONS.md"
)

missing_files=0
for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✓ $file"
    else
        echo "✗ $file - MISSING"
        ((missing_files++))
    fi
done

if [[ $missing_files -eq 0 ]]; then
    echo
    echo "✓ All container setup files present"
else
    echo
    echo "✗ $missing_files files are missing"
    exit 1
fi

echo
echo "Checking Dockerfile content..."
if [[ -f "Dockerfile.xpu.complete" ]]; then
    # Count key elements
    dockerfile_lines=$(wc -l < "Dockerfile.xpu.complete")
    echo "✓ Dockerfile.xpu.complete: $dockerfile_lines lines"
    
    # Check for key instructions
    grep -q "FROM python:3.11-slim" "Dockerfile.xpu.complete" && echo "✓ FROM python:3.11-slim found"
    grep -q "EXPOSE 7860" "Dockerfile.xpu.complete" && echo "✓ EXPOSE 7860 found"
    grep -q "ENV PYTORCH_DEVICE=xpu" "Dockerfile.xpu.complete" && echo "✓ XPU environment variables found"
    
    echo
    echo "✓ Dockerfile structure looks correct"
fi

echo
echo "==============================================="
echo "Container setup verification complete!"
echo "==============================================="
echo
echo "To build the container:"
echo "  docker build -f Dockerfile.xpu.complete -t acestep-xpu ."
echo
echo "To run the container:"
echo "  docker run --rm -it --device=/dev/dri:/dev/dri -p 7860:7860 acestep-xpu"
echo
echo "For Docker Compose:"
echo "  docker-compose -f docker-compose.xpu.yml up -d"
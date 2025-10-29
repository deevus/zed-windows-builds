#!/bin/bash

# Script to prepare release files from build artifacts
# This script handles both Vulkan and OpenGL builds, creating releases even if one fails

set -euo pipefail

ARTIFACTS_DIR="artifacts"
RELEASE_DIR="release"

# Create release directory
mkdir -p "$RELEASE_DIR"

# Check if CLI build exists
if [ -f "$ARTIFACTS_DIR/cli-release/cli.exe" ]; then
    echo "Found CLI build, adding to release..."
    mv "$ARTIFACTS_DIR/cli-release/cli.exe" "$RELEASE_DIR/cli.exe"
    zip -j "$RELEASE_DIR/cli.zip" -9 "$RELEASE_DIR/cli.exe"
fi

# Check if DX11 build exists
if [ -f "$ARTIFACTS_DIR/editor-dx11-release/zed.exe" ]; then
    echo "Found DX11 build, adding to release..."
    mv "$ARTIFACTS_DIR/editor-dx11-release/zed.exe" "$RELEASE_DIR/zed.exe"
    zip -j "$RELEASE_DIR/zed.zip" -9 "$RELEASE_DIR/zed.exe"
fi

# Check if OpenGL build exists
if [ -f "$ARTIFACTS_DIR/editor-opengl-release/zed.exe" ]; then
    echo "Found OpenGL build, adding to release..."
    mv "$ARTIFACTS_DIR/editor-opengl-release/zed.exe" "$RELEASE_DIR/zed-opengl.exe"
    zip -j "$RELEASE_DIR/zed-opengl.zip" -9 "$RELEASE_DIR/zed-opengl.exe"
fi

# Generate checksums for existing files in release folder
cd "$RELEASE_DIR"
if ls * >/dev/null 2>&1; then
    echo "Generating checksums..."
    sha256sum * > sha256sums.txt
    echo "Release files prepared successfully:"
    ls -la
else
    echo "Error: No release files found in release folder"
    exit 1
fi

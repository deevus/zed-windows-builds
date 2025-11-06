#!/bin/bash

# Script to prepare release files from build artifacts
# This script handles CLI, DX11, and OpenGL builds, creating releases even if some fail

set -euo pipefail

ARTIFACTS_DIR="artifacts"
RELEASE_DIR="release"

# Create release directory
mkdir -p "$RELEASE_DIR"

# Check if CLI build exists
if [ -f "$ARTIFACTS_DIR/cli-release/cli.exe" ]; then
    echo "Found CLI build, adding to release..."

    cd "$ARTIFACTS_DIR/cli-release"
    mv cli.exe zed.exe
    cd - > /dev/null
fi

# Check if DX11 build exists
if [ -f "$ARTIFACTS_DIR/editor-dx11-release/zed.exe" ]; then
    echo "Found DX11 build, adding to release..."

    mkdir -p "$ARTIFACTS_DIR/editor-dx11-release/zed/bin"
    mv "$ARTIFACTS_DIR/editor-dx11-release/zed.exe" "$ARTIFACTS_DIR/editor-dx11-release/zed"
    cp "$ARTIFACTS_DIR/cli-release/zed.exe" "$ARTIFACTS_DIR/editor-dx11-release/zed/bin"

    zip -r "$RELEASE_DIR/zed.zip" -9 "$ARTIFACTS_DIR/editor-dx11-release/zed/"
fi

# Check if OpenGL build exists
if [ -f "$ARTIFACTS_DIR/editor-opengl-release/zed.exe" ]; then
    echo "Found OpenGL build, adding to release..."

    mkdir -p "$ARTIFACTS_DIR/editor-opengl-release/zed/bin"
    mv "$ARTIFACTS_DIR/editor-opengl-release/zed.exe" "$ARTIFACTS_DIR/editor-opengl-release/zed"
    cp "$ARTIFACTS_DIR/cli-release/zed.exe" "$ARTIFACTS_DIR/editor-opengl-release/zed/bin"

    zip -r "$RELEASE_DIR/zed-opengl.zip" -9 "$ARTIFACTS_DIR/editor-opengl-release/zed/"
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

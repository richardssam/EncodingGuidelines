#!/bin/bash

# Script to create a standalone FFmpeg bundle for Linux (RHEL 9 / Rocky 9)
# from Conan full_deploy output.
# Usage: ./create-linux-bundle.sh [source_deploy_dir] [target_dir]

SOURCE_DIR=${1:-build-rhel9/full_deploy/host}
TARGET_DIR=${2:-ffmpeg-linux-standalone}

echo "Creating Linux bundle in $TARGET_DIR from $SOURCE_DIR..."

# Create target structure
mkdir -p "$TARGET_DIR/bin"
mkdir -p "$TARGET_DIR/lib"

# 1. Copy FFmpeg binaries
FFMPEG_BIN=$(find "$SOURCE_DIR/ffmpeg" -name "ffmpeg" -type f | head -n 1)
FFPROBE_BIN=$(find "$SOURCE_DIR/ffmpeg" -name "ffprobe" -type f | head -n 1)

if [ -n "$FFMPEG_BIN" ]; then
    cp "$FFMPEG_BIN" "$TARGET_DIR/bin/"
    cp "$FFPROBE_BIN" "$TARGET_DIR/bin/"
else
    echo "Error: FFmpeg binaries not found in $SOURCE_DIR/ffmpeg"
    exit 1
fi

# 2. Copy all .so files from all host packages
echo "Copying shared libraries..."
find "$SOURCE_DIR" -name "*.so*" -exec cp -d {} "$TARGET_DIR/lib/" \;

# 3. Use patchelf to fix RUNPATH
# This allows the binary to find its libraries in the relative ../lib folder
if command -v patchelf >/dev/null 2>&1; then
    echo "Fixing RUNPATHs using patchelf..."
    patchelf --set-rpath '$ORIGIN/../lib' "$TARGET_DIR/bin/ffmpeg"
    patchelf --set-rpath '$ORIGIN/../lib' "$TARGET_DIR/bin/ffprobe"
    
    # Also fix RPATH for the libraries themselves so they can find each other
    for lib in "$TARGET_DIR/lib"/*.so*; do
        if [ -f "$lib" ] && [ ! -L "$lib" ]; then
            patchelf --set-rpath '$ORIGIN' "$lib"
        fi
    done
else
    echo "Warning: patchelf not found. RUNPATHs not updated."
    echo "You may need to run: dnf install -y patchelf"
fi

echo "Done! Standalone Linux bundle created in '$TARGET_DIR'."
echo "You can move this folder to any compatible Linux system."

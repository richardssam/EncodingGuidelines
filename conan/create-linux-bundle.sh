#!/bin/bash

# Script to create a standalone FFmpeg bundle for Linux (RHEL 9 / Rocky 9)
# This script should be run in the environment where FFmpeg was built.
# Usage: ./create-linux-bundle.sh [install_prefix] [target_dir]

PREFIX=${1:-/usr/local}
TARGET_DIR=${2:-ffmpeg-linux-standalone}

echo "Creating Linux bundle in $TARGET_DIR from $PREFIX..."

# Create target structure
mkdir -p "$TARGET_DIR/bin"
mkdir -p "$TARGET_DIR/lib"

# Check if binaries exist
if [ ! -f "$PREFIX/bin/ffmpeg" ]; then
    echo "Error: FFmpeg binary not found at $PREFIX/bin/ffmpeg"
    exit 1
fi

# 1. Copy FFmpeg binaries
cp "$PREFIX/bin/ffmpeg" "$TARGET_DIR/bin/"
cp "$PREFIX/bin/ffprobe" "$TARGET_DIR/bin/"

# 2. Identify and copy shared library dependencies
echo "Identifying shared library dependencies..."

# Temporary file to store unique dependencies
DEPS_FILE=$(mktemp)

# Get dependencies for ffmpeg and ffprobe
for binary in "$TARGET_DIR/bin/ffmpeg" "$TARGET_DIR/bin/ffprobe"; do
    # ldd lists dependencies. We filter for libraries in /usr/local (or custom prefix)
    ldd "$binary" | grep "=> /" | awk '{print $3}' >> "$DEPS_FILE"
done

# Sort and unique
sort -u "$DEPS_FILE" -o "$DEPS_FILE"

# Copy found libraries
while read -r lib; do
    # Only copy libraries that are within our custom prefix (to avoid bundling system glibc etc)
    if [[ "$lib" == "$PREFIX"* ]] || [[ "$lib" == "/usr/local"* ]]; then
        lib_name=$(basename "$lib")
        if [ ! -f "$TARGET_DIR/lib/$lib_name" ]; then
            echo "Copying dependency: $lib_name"
            cp "$lib" "$TARGET_DIR/lib/"
        fi
    fi
done < "$DEPS_FILE"

rm "$DEPS_FILE"

# 3. Use patchelf to fix RUNPATH
# This allows the binary to find its libraries in the relative ../lib folder
if command -v patchelf >/dev/null 2>&1; then
    echo "Fixing RUNPATHs using patchelf..."
    patchelf --set-rpath '$ORIGIN/../lib' "$TARGET_DIR/bin/ffmpeg"
    patchelf --set-rpath '$ORIGIN/../lib' "$TARGET_DIR/bin/ffprobe"
    
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
echo "You can move this folder to any similar RHEL 9 / Rocky 9 system."

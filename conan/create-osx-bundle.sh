#!/bin/bash

# Script to create a standalone FFmpeg bundle from Conan full_deploy output
# Usage: ./create_bundle.sh [source_deploy_dir] [target_dir]

SOURCE_DIR=${1:-build-osx/full_deploy/host}
TARGET_DIR=${2:-ffmpeg-standalone}

echo "Creating bundle in $TARGET_DIR from $SOURCE_DIR..."

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

# 2. Copy all dylibs from all host packages
find "$SOURCE_DIR" -name "*.dylib" -exec cp {} "$TARGET_DIR/lib/" \;

# 3. Fix RPATHs in binaries to look in ../lib relative to the executable
# We use @executable_path/../lib
echo "Fixing RPATHs in binaries..."
install_name_tool -add_rpath "@executable_path/../lib" "$TARGET_DIR/bin/ffmpeg" 2>/dev/null || true
install_name_tool -add_rpath "@executable_path/../lib" "$TARGET_DIR/bin/ffprobe" 2>/dev/null || true

# 4. Fix RPATHs in libraries to look in the same folder
echo "Fixing RPATHs in libraries..."
for dylib in "$TARGET_DIR/lib"/*.dylib; do
    install_name_tool -add_rpath "@loader_path/" "$dylib" 2>/dev/null || true
done

echo "Done! You can now run the standalone ffmpeg at $TARGET_DIR/bin/ffmpeg"
echo "You can move the $TARGET_DIR folder anywhere."

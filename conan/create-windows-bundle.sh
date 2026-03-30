#!/bin/bash

# Script to create a standalone FFmpeg bundle for Windows (MSYS2/MinGW64)
# This script should be run within an MSYS2 MinGW64 environment.
# Usage: ./create_windows_bundle.sh [source_deploy_dir] [target_dir]

SOURCE_DIR=${1:-build-windows/full_deploy/host}
TARGET_DIR=${2:-ffmpeg-windows-standalone}

echo "Creating Windows bundle in $TARGET_DIR from $SOURCE_DIR..."

# Create target structure
mkdir -p "$TARGET_DIR"

# 1. Copy all EXE and DLL files from Conan deploy folder
echo "Copying binaries from Conan deploy folder..."
find "$SOURCE_DIR" -name "*.exe" -exec cp {} "$TARGET_DIR/" \;
find "$SOURCE_DIR" -name "*.dll" -exec cp {} "$TARGET_DIR/" \;

# 2. Identify and copy missing system DLLs from MinGW64
echo "Identifying missing MinGW64 system dependencies..."

# Temporary file to store unique dependencies
DEPS_FILE=$(mktemp)

# Find dependencies for all .exe and .dll files already in the target dir
for file in "$TARGET_DIR"/*.exe "$TARGET_DIR"/*.dll; do
    if [ -f "$file" ]; then
        # ldd lists dependencies; we look for those in /mingw64/bin/
        ldd "$file" | grep " /mingw64/bin/" | awk '{print $3}' >> "$DEPS_FILE"
    fi
done

# Sort and unique the dependency list
sort -u "$DEPS_FILE" -o "$DEPS_FILE"

# Copy found system DLLs into the target directory
while read -r dep; do
    if [ -f "$dep" ]; then
        dep_name=$(basename "$dep")
        if [ ! -f "$TARGET_DIR/$dep_name" ]; then
            echo "Copying system dependency: $dep_name"
            cp "$dep" "$TARGET_DIR/"
        fi
    fi
done < "$DEPS_FILE"

rm "$DEPS_FILE"

echo "Done! The standalone bundle is ready in the '$TARGET_DIR' folder."
echo "You can move this folder to any Windows machine and it should be runnable."

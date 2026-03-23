---
layout: default
nav_order: 5.7
title: Building FFmpeg with Conan
parent: Encoding Overview
---

# Conan Build System

On windows:
We are using msys2, but using the mingw toolchain so the resulting app is native.

For now, even though my OS is actually arm I'm actually going to run as x86_64 just to get a build.

export CONAN_HOME="/c/.c2"

# This installs the native Windows 64-bit toolchain

wxmingw-w64-x86_64-gdb mingw-w64-x86_64-make
pacman -S mingw-w64-x86_64-python-pip mingw-w64-x86_64-python-ninja
pacman -S mingw-w64-x86_64-nasm mingw-w64-x86_64-yasm
pacman -S base-devel
pip install conan

Install C++ v14 redist library - <https://www.microsoft.com/en-gb/download/details.aspx?id=48145>

cd /z/cci/recipes/ffmpeg/all
conan export . --name ffmpeg --version 8.1
cd /z/libvmaf_recipe
conan export . --version 3.0.0

# Set this first to prevent path errors

export MSYS2_ARG_CONV_EXCL="*"

# Its possible that we really need to set it to this

export MSYS2_ARG_CONV_EXCL=""
conan install . \
  -pr:h=profiles/msys2-ffmpeg8.1 \
  -pr:b=default \
  --output-folder=build-msys2 \
  --build=missing

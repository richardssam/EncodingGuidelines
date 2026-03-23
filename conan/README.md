---
layout: default
nav_order: 5.7
title: Building FFmpeg with Conan
parent: Encoding Overview
---

# Conan Build System

## Windows

Windows is the more complex install since ffmpeg requires so many different libraries that require different build environments.
What we have found that works is using the [msys2](https://www.msys2.org/) environment with the mingw toolchain.

Start by downloading msys2, once its installed, you will be presented with a number of different launch environments. You want to use the one that has "mingw" in the name, e.g. "MSYS2 MinGW 64-bit".

Its worth noting, that the this process works with x86_64, but not with arm64 (although that is something I'm hoping to eventually get working).

I would recommend checking out the [Encoding Guidelines](https://github.com/AcademySoftwareFoundation/EncodingGuidelines) and then going to the conan folder.

There you can run windows_setup.sh to install the required tools and conan.

Once you have that running, you want to run:

```bash
cd EncodingGuidelines/conan
source windows-setup.sh
```

You can then run:

```bash
source windows_ffmpeg_build.sh
```

to build ffmpeg with conan, this will install ffmpeg in the conan/build-windows/full_deploy/host/ffmpeg/ folder.
You can do an initial test of the code by running the build-windows/conanrun.bat script in a shell. This will set up the environment variables so that you can run the ffmpeg executables.

## OSX

```bash
cd EncodingGuidelines/conan
source windows_setup.sh  # or linux-osx-setup.sh
chmod +x ffmpeg-8.1-osx-build.sh
./ffmpeg-8.1-osx-build.sh
```

### Creating a Standalone Bundle (macOS)

If you want to create a portable folder containing FFmpeg and all its dependencies:

```bash
cd EncodingGuidelines/conan
chmod +x create_bundle.sh
./create_bundle.sh
```

This will create an `ffmpeg-standalone` folder with `bin/ffmpeg` and all required `.dylib` files. You can move this folder anywhere and run FFmpeg from it.

## Linux

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

Note, this build does not include x265, aom, or zimg. These are not built by default with conan, there are unresolved issues with building them with conan on windows.

## OSX

```bash
cd EncodingGuidelines/conan
source linux-osx-setup.sh
chmod +x ffmpeg-8.1-osx-build.sh
./ffmpeg-8.1-osx-build.sh
```

### Creating a Standalone Bundle (macOS)

```bash
cd EncodingGuidelines/conan
chmod +x create-osx-bundle.sh
./create-osx-bundle.sh
```

## Linux

If you are building for RHEL 9 / Rocky 9:

```bash
cd EncodingGuidelines/conan
# Ensure patchelf is installed
# sudo dnf install patchelf
chmod +x create-linux-bundle.sh
./create-linux-bundle.sh
```

This will create an `ffmpeg-linux-standalone` folder from the `build-rhel9/full_deploy` output.

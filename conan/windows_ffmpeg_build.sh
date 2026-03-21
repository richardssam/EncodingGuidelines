export CONAN_HOME="/c/.c2"

export MSYS2_ARG_CONV_EXCL=""
conan install . \
  -pr:h=profiles/x64-ffmpeg8.1 \
  -pr:b=profiles/x64-ffmpeg8.1 \
  --output-folder=build-msys2 \
  --build=missing

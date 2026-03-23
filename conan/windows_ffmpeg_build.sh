export CONAN_HOME="/c/.c2"

export MSYS2_ARG_CONV_EXCL=""
conan install . \
  -pr:h=profiles/msys2-ffmpeg8.1 \
  -pr:b=profiles/msys2-ffmpeg8.1 \
  --output-folder=build-windows \
  -o ffmpeg_version=8.1 \
  --build=missing --deployer=full_deploy

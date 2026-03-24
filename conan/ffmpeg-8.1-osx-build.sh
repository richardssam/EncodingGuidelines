 conan install . \
  -pr:h=profiles/osx-ffmpeg8.1 \
  -pr:b=profiles/osx-ffmpeg8.1 \
  --output-folder=build-osx \
  -o ffmpeg_version=8.1 \
  --build=missing \
  --build=ffmpeg

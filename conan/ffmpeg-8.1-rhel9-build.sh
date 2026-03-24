 conan install . \
  -pr:h=profiles/rhel9-ffmpeg8.1 \
  -pr:b=profiles/rhel9-ffmpeg8.1 \
  --output-folder=build-rhel9 \
  -o ffmpeg_version=8.1 \
  --build=missing \
  --build=type:build \
  -c tools.system.package_manager:mode=install \
  --deployer=full_deploy
  

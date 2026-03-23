
pip install conan
cd recipes/ffmpeg/all
conan export . --name ffmpeg --version 8.1
cd ../../opencolorio/all
conan export . --name opencolorio --version 2.5.1
cd ../../libvmaf/all
conan export . --name libvmaf --version 3.0.0
cd ../../..
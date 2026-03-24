   dnf install epel-release -y
   dnf config-manager --set-enabled crb
   dnf -y install python3-pip python3-devel clang
   dnf -y install python3-pip python3-devel 
   source linux-osx-setup.sh 
   dnf install cmake diffutils perl nasm
   source ffmpeg-8.1-rhel9-build.sh 

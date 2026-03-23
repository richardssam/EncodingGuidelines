from conan import ConanFile
from conan.tools.cmake import cmake_layout

class EncodingGuidelines(ConanFile):
    name = "EncodingGuidelines"
    settings = "os", "compiler", "build_type", "arch"
    # VirtualRunEnv creates the 'conanrun.sh' script to set your PATH
    generators = "VirtualRunEnv"

    options = {"ffmpeg_version": ["6.1.1", "7.1.3", "8.0.1", "8.1", "8.1.1"]}
    default_options = {"ffmpeg_version": "8.0.1"}

    def requirements(self):
        if self.options.ffmpeg_version in ["8.1", "8.1.1"]:
            # For the latest, we point to the release branch
            self.requires(f"ffmpeg/{self.options.ffmpeg_version}")
            # OpenAPV is a specific requirement for ASWF
            self.requires("openapv/[>=0.2.0.4]")
            self.requires("openjpeg/2.5.2", run=True)
            self.requires("opencolorio/2.5.1", run=True, force=True)
        elif self.options.ffmpeg_version == "6.1.1":
            self.requires("ffmpeg/6.1.1")
            self.requires("libx264/cci.20240224", run=True)
            self.requires("openjpeg/2.5.2", run=True)
        elif self.options.ffmpeg_version == "7.1.3":
            self.requires("ffmpeg/7.1.3")
            self.requires("libx264/cci.20240224", run=True)
            self.requires("openjpeg/2.5.4", run=True)
        else:
            self.requires("ffmpeg/8.0.1")
            self.requires("libx264/cci.20250910", run=True)
            self.requires("openjpeg/2.5.4", run=True)
        
        # We explicitly require these so that Conan's VirtualRunEnv picks up 
        # their paths for DYLD_LIBRARY_PATH/PATH.
        self.requires("libvmaf/3.0.0", run=True)
        self.requires("openssl/3.1.7", run=True)
        self.tool_requires("nasm/2.16.01")
        #self.requires("libx265/3.6", run=True)
        #self.requires("libvpx/1.16.0", run=True)
        #self.requires("libmp3lame/3.100", run=True)
        #self.requires("libfdk_aac/2.0.3", run=True)
        #self.requires("libwebp/1.6.0", run=True)
        #self.requires("libaom-av1/3.6.1", run=True)
        #self.requires("libsvtav1/2.1.0", run=True)
        #self.requires("dav1d/1.5.3", run=True)
        #self.requires("zimg/3.0.5", run=True)
        #self.requires("openh264/2.6.0", run=True)
        #self.requires("opus/1.5.2", run=True)
        #self.requires("vorbis/1.3.7", run=True)
        #self.requires("harfbuzz/8.3.0", run=True)
        #self.requires("freetype/2.13.2", run=True)

    def configure(self):
        ffmpeg = self.options["ffmpeg"]
        # Universal guidelines options
        # 1:1 mapping of your --enable flags
        ffmpeg.with_gpl = True
        ffmpeg.with_version3 = True
        ffmpeg.with_nonfree = True
        ffmpeg.shared = True
        
        # Hardware & Frameworks
        ffmpeg.with_videotoolbox = True # --enable-videotoolbox
        
        # External Libraries
        ffmpeg.with_harfbuzz = True     # --enable-libharfbuzz
        ffmpeg.with_freetype = True     # --enable-libfreetype
        ffmpeg.with_libplacebo = True   # --enable-libplacebo
        ffmpeg.with_openapv = True      # --enable-liboapv
        ffmpeg.with_openjpeg = True     # --enable-libopenjpeg
        ffmpeg.with_libvmaf = True         # --enable-libvmaf
        ffmpeg.with_svtav1 = True       # --enable-libsvtav1
        ffmpeg.with_libx264 = True      # --enable-libx264
        ffmpeg.with_libx265 = False      # --enable-libx265
        ffmpeg.with_libaom = False       # --enable-libaom
        ffmpeg.with_libzimg = False      # --enable-libzimg
        ffmpeg.with_libvpx = True
        ffmpeg.with_dav1d = True
        self.options["dav1d"].assembly = False
        self.options["libx265"].assembly = False
        
        # Enable 8.1 specific features
        if self.options.ffmpeg_version in ["8.1", "8.1.1"]:
            ffmpeg.with_opencolorio = True  # --enable-libopencolorio

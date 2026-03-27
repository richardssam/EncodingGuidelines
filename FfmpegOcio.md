---
layout: default
title: FFmpeg OCIO Filter
nav_order: 5.5
parent: Encoding Overview
---

# FFmpeg OCIO Filter

With the introduction of ffmpeg 8.1 a [OCIO](https://ocio.readthedocs.io/en/latest/) [filter](https://ffmpeg.org/ffmpeg-filters.html#ocio) has been added. This allows you to convert from EXR files directly to encoded media using an OCIO filter to convert the colorspace correctly without needing an intermediate file.

If you are encoding to YCbCr you will need to do the OCIO conversion in RGB colorspace first, and then convert to YCbCr. This is because OCIO doesn't know how to convert to YCbCr out of the box, and Ffmpeg handles the variants like 420, 422, and 444.

## Example Usage

### Using OCIO-Display

This example is encoding to a 10-bit h264 quicktime.

```console
ffmpeg -y  -framerate 24 -start_number <STARTFRAME> -i SOURCEFRAMES.%05d.exr \
   -c:v h264 -pix_fmt yuv420p10le -crf 18 -preset slow \
   -vf "ocio=input=ACEScct:display=sRGB - Display:view=ACES 1.0 - SDR Video:format=rgb48,scale=in_color_matrix=bt709:out_color_matrix=bt709,format=yuv444p10"   OUTPUTFILE.mov
```

### Using an output colorspace (in this case ACEScct)

This is using the older style colorspace conversion where you are specifying an output colorspace (in this case ACEScct).

```console
ffmpeg -y  -framerate 24 -start_number <STARTFRAME> -i SOURCEFRAMES.%05d.exr \
   -c:v h264 -pix_fmt yuv420p10le -crf 18 -preset slow \
    -vf "ocio=input=ACEScg:output=ACEScct:format=rgb48,scale=in_color_matrix=bt709:out_color_matrix=bt709,format=yuv444p10"   OUTPUTFILE.mov
```

The format parameter that's part of the OCIO filter allows you to specify an output pixel_format that OCIO will be converting to. This has to be an RGB colorspace since OCIO doesn't know how to convert to YCbCr. If you do not supply the format, the output will match the input with the exception of half-floats which will be converted to full floats (due to poor support for half-floats).

Note, you can also specify the OCIO config file as a “config” parameter, but otherwise it will default to the OCIO environment variable.

## Converting to a HDR image sequence

This is converting from a ACEScg image sequence to a HDR PQ quicktime.

```console
ffmpeg -y -framerate 24 -start_number <STARTFRAME> -i SOURCEFRAMES.%04d.exr -c:v libx265 -pix_fmt yuv422p10le -threads 0 -vf "ocio=input=ACEScg:display=Rec.2100-PQ - Display:view=ACES 1.1 - HDR Video (1000 nits & Rec.2020 lim):format=rgb48,scale=in_range=full:in_color_matrix=bt2020:out_range=tv:out_color_matrix=bt2020" -color_range tv -color_trc smpte2084 -color_primaries bt2020 -colorspace bt2020nc -tag:v hvc1  \
    -x265-params "hdr-opt=1:colorprim=bt2020:transfer=smpte2084:colormatrix=bt2020nc:range=limited:master-display=G(13250,34500)B(7500,3000)R(34000,16000)WP(15635,16450)L(10000000,1):max-cll=1000,400" OUTPUTFILE.mov
```

## Converting from an HDR movie to a ACEScg image sequence

To test converting from an HDR movie, we are going to create an HDR movie first:

```console
ffmpeg -y -framerate 24 -start_number 6100 -i /Users/sam/git/EncodingGuidelines/enctests/sources/hdr_sources/sparks/SPARKS_ACES_%05d.exr -c:v libx265 -pix_fmt yuv444p12le -vf "ocio=input=ACEScg:display=Rec.2100-PQ - Display:view=ACES 1.1 - HDR Video (1000 nits & Rec.2020 lim):format=rgb48,scale=in_range=full:in_color_matrix=bt2020:out_range=tv:out_color_matrix=bt2020" -color_range tv -color_trc smpte2084 -color_primaries bt2020 -colorspace bt2020nc -tag:v hvc1      -x265-params "lossless=1:hdr-opt=1:colorprim=bt2020:transfer=smpte2084:colormatrix=bt2020nc:range=limited:master-display=G(13250,34500)B(7500,3000)R(34000,16000)WP(15635,16450)L(10000000,1):max-cll=1000,400" sparks_lossless_h265.mov
```

Note this is both 12-bit 444 and lossless, to make the comparison a little easier to rule out any encoding artifacts.

Then we can convert it back to EXR's:

```console
ffmpeg -y -i sparks_lossless_h265.mov -threads 0 -vf "ocio=input=ACEScg:display=Rec.2100-PQ - Display:view=ACES 1.1 - HDR Video (1000 nits & Rec.2020 lim):inverse=1:format=gbrpf32le,scale=out_range=full:out_color_matrix=bt2020"  testoutput/testoutput.%04d.exr
```

So while this will limit the max luminance to 1000 nits, it will give you a wide gamut with an higher dynamic range that you can convert back into a linear range which will be hugely superior to rec709 or g24p3. Obviously this is not as good as using the original EXR files, but it is certainly an improvement over rec709, giving you the ability to change the exposure

If your viewer supported HDR, this shows that you could internally convert it to ACEScg, so that any test color correction you might be doing in the viewer would be fairly representative of what it would be like if you were reading from an openEXR frame. Obviously the best results would be to use the EXR frames, but its certainly an improvement over rec709.

## Converting from HDR image sequence to ACEScg

## Filter Arguments

| Option | Description |
| ------ | ----------- |
| config | By default the filter will use the OCIO config defined by the OCIO environment variable, but this parameter allows you to explicitly specify its location. If you are getting started, you can use config=ocio://studio-config-v1.0.0_aces-v1.3_ocio-v2.1 which specifies one of the built in defaults. |
| input | Set the input colorspace. |
| output | Set the output colorspace. |
| display | Set the display colorspace, used in combination with view. |
| view | Set the view colorspace, used in combination with display. |
| inverse | When used in combination with display and view, this inverts the transform, so going from a display/view to the "input colorspace". |
| format | Allow you to specify the output pix_fmt of the OCIO filter. This *has* to be a RGB colorspace, so you really are limited to rgb24, rgba, rgb48, rgba48, gbrp10, gbrp12, gbrpf32le, gbrapf32le, for most encoding we would recommend rgb48. By default this is the pix_fmt of the input with the exception of gbrpf16le which we automatically convert to a 32bit version (half float is not fully supported by ffmpeg, swscale in particular). |
| context_params | Allow you to specify additional context parameters for the OCIO filter. This is a list of key=value pairs, separated by colons. |

## Building ffmpeg with OCIO support

If you are already manually building ffmpeg, you can enable OCIO support by adding the following flag to the configure script:

```console
--enable-libopencolorio
```

This does require opencolorio to be installed on the system, and be found by pkgconfig.

If not, you may want to refer to the docker container build files in the [docker](docker) directory. In particular the [rocky-ffmpeg-8.1](docker/rocky-ffmpeg-8.1) directory. There is also a conan recipe in the [conan](conan/README.md) directory that can be used to build ffmpeg with OCIO support on MacOS, linux and windows.

We do also want to flag a patch that didnt make it into the ffmpeg 8.1 release - <https://code.ffmpeg.org/FFmpeg/FFmpeg/pulls/21799>. This patch fixes an issue where the ocio filter was not able to output half-float formats and also can crash filters like zscale. Hopefully this will make it into the following release. The above build recipes do include this patch.

## Timing Tests

For some simple timing tests, we are comparing oiiotool using --parallel-frames (meaning the initial conversion is run in as many threads as possible) and ffmpeg (both single threaded and with 4 threads). This is a 4 second 4k exr image sequence of 200 frames (sparks) and we are encoding to prores_videotoolbox 422 HQ on a M2 Macbook Pro. We picked this particular codec since its fast, and works at high bit-depths (10 and 12-bit).

| Task | Elapsed time Seconds | Notes |
| :--- | ---: | :--- |
| oiiotool | 101.46 | Media conversion to PNG serially. |
| oiiotool with parallel-frames | 44.91 | Media conversion to PNG with --parallel-frames |
| basic ffmpeg | 2.87 | Just converting the resulting frames from PNG to a quicktime |
| oiiotool + ffmpeg | 47.78 | Combining parallel-frames and the ffmpeg generation |
| ffmpeg with 0 threads | 19.58 | This is the default option |
| ffmpeg with 1 threads | 127.75 | Single threaded. |
| ffmpeg with 2 threads | 65.90 | |
| ffmpeg with 4 threads | 33.95 | |
| ffmpeg with 6 threads | 23.74 | |
| ffmpeg with 8 threads | 37.75 | |

We recommend leaving it with the default of 0 threads (i.e. dont specify anything). It is worth noting that OCIO using the CPU is not super fast (although clearly faster than the alternative), we will explore using vulkan to accelerate this in the future.

## Slate and burn-in generation

By Adding OCIO to ffmpeg it allows us to generate slates and burn-ins in the correct colorspace without needing to create an intermediate file. Good examples of the need for this are documented by Netflix in their [Netflix Post Production Guide](https://partnerhelp.netflixstudios.com/hc/en-us/articles/360057627293-VFX-Slates-Overlays-Guidelines) post.

TODO Provide an extreme example of slate creation and text overlays.

## Highlight places it might give errors

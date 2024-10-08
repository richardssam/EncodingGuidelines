---
layout: default
nav_order: 4.6
title: DNxHD Encoding
parent: Codec Comparisons
---


# DNxHD/DNxHR

<details open markdown="block">
  <summary>
    Table of contents
  </summary>
  {: .text-delta }
1. TOC
{:toc}
</details>

Avid [DNxHD](https://en.wikipedia.org/wiki/Avid_DNxHD) ("Digital Nonlinear Extensible High Definition") is a lossy post-production codec that is intended for use for editing as well as a presentation format.

There are a number of pre-defined resolutions, frame-rates and bit-rates that are supported, see [AVID Resolutions](#dnxhd-profiles) for a list, and these are commonly requested by Editorial. However, we recommend using the DNxHR version of the codec, since it allows quite a bit more flexibility for larger image sizes than HD, more flexible frame rates and bit-rates of up to 3730Mbit/s (See  [DNxHR-Codec-Bandwidth-Specifications](https://avid.secure.force.com/pkb/articles/en_US/White_Paper/DNxHR-Codec-Bandwidth-Specifications) ).


Supported pixel formats: yuv422p yuv422p10le yuv444p10le gbrp10le

Example encoding:

<!---
name: test_dnxhd_mov
sources: 
- sourceimages/smptehdbars_10.dpx.yml
comparisontest:
   - testtype: idiff
     compare_image: ../sourceimages/smptehdbars_10_yuv422p10le.png
   - testtype: assertresults
     tests:
     - assert: less
       value: max_error
       less: 0.00195
-->
```
ffmpeg -r 24 -start_number 1 -i inputfile.%04d.png -frames:v 200 -c:v dnxhd \
    -pix_fmt yuv422p10le -profile:v dnxhr_hqx \
    -vf "scale=in_range=full:in_color_matrix=bt709:out_range=tv:out_color_matrix=bt709" \
    -color_range tv -colorspace bt709 -color_primaries bt709 -color_trc bt709 -y  outputfile.mov
```


## ffmpeg DNxHR Profiles

| Profile name | Profile description | Profile # | Pix Fmt | Bit Depth | Compression Ratio |
|:----------|:-----------|:-----------|:-----------|:-----------|:-----------|
| dnxhr_lb | Low Bandwidth | 1 | YUV 4:2:2 (yuv422p) | 8 | 22:1 |
| dnxhr_sq | Standard Quality | 2 | YUV 4:2:2  (yuv422p) | 8 | 7:1 |
| dnxhr_hq | High Quality | 3 | YUV 4:2:2  (yuv422p) | 8 | 4.5:1 |
| dnxhr_hqx | High Quality | 4 | YUV 4:2:2  (yuv422p, yuv422p10)  | 12 (*) | 5.5: 1 |
| dnxhr_444 | DNxHR 4:4:4 | 5 | YUV 4:4:4 or RGB  (yuv444p10, gbrp10) | 12 (*) | 4.5:1 |

There really are not any significant flags to be used, since the quality is adjusted automatically to fit the compression ratio. Similarly the bit-rate flag has no impact on this. For more Bit-rate control, see the [DNxHD settings](#dnxhd-profiles) below.

(*) The 12-bit depth is what the codec can support, but does not appear to be supported by ffmpeg, since the encoding only allows 10-bit image data to be encoded.

NOTE, we have sometimes seen incompatibility issues with DNxHD Quicktimes not being read by Black Magic devices (e.g. the HyperDeck Studio), so there may be cases where you will need to use Resolve or Adobe Media Encoder to create compatible media.

## ffmpeg RGB support

<!---
name: test_dnxhd_rgb
sources: 
- sourceimages/smptehdbars_10.dpx.yml
comparisontest:
   - testtype: idiff
   - testtype: assertresults
     tests:
     - assert: less
       value: max_error
       less: 0.00195
-->
```
ffmpeg -y -r 24 -i inputfile.%04d.png -vframes 100 \
     -c:v dnxhd -profile:v dnxhr_444 \
     -color_primaries bt709 -color_range tv -color_trc bt709 -colorspace rgb \
     -pix_fmt gbrp10le outputfile.mov
```

## AVID friendly MXF

{: .warning }
This is currently under development, use at your own risk.

There are two types of MXF files, Op-atom and OP1a. Op-atom is designed for a single piece of media, whether its audio or video, so a clip with both would be split into two sections. OP1a is a streaming format, where the audio and video streams are interleaved (see [MXF](https://web.archive.org/web/20121119151859/http://www.avid.com/static/resources/common/documents/mxf.pdf)). 

### OP1a MXF

This is appropriate for deliveries where this only a video component, not a mixed format.

<!---
name: test_dnxhd_op1a_mxf
sources: 
- sourceimages/smptehdbars_8.png.yml
comparisontest:
   - testtype: idiff
     compare_image: ../sourceimages/smptehdbars_8_yuv422p.png
   - testtype: assertresults
     tests:
     - assert: less
       value: max_error
       less: 0.00195
-->
```
ffmpeg -y -r 24 -start_number 2500 -i inputfile.%04d.png  -vframes 100 \
    -pix_fmt yuv422p \
    -vf "scale=in_range=full:in_color_matrix=bt709:out_range=tv:out_color_matrix=bt709" \
    -c:v dnxhd -profile:v dnxhr_sq \
      -metadata project="MY PROJECT" \
      -metadata material_package_name="MY CLIP"  -timecode 01:00:20:00 \
    -color_range tv -colorspace bt709 -color_primaries bt709 -color_trc bt709  \
    outputfile.mxf
```

These can be imported directly into the AVID, although it will need to do some unpacking. For the fastest import you probably want to use OpAtom (see below). If you want to import with a reel-name, using the AAF wrapper (see below) is the recommended approach.

### Op-Atom MXF

AVID prefer deliveries in MXF using the Avid Op-Atom format. Generating the Op-Atom format used to be a separate application, but its now integrated into ffmpeg. This worked for a single piece of media (i.e. just video, or audio, not both).

<!---
name: test_dnxhd_opatom_mxf
sources: 
- sourceimages/smptehdbars_8.png.yml
comparisontest:
   - testtype: idiff
     compare_image: ../sourceimages/smptehdbars_8_yuv422p.png
   - testtype: assertresults
     tests:
     - assert: less
       value: max_error
       less: 0.00195
-->
```
ffmpeg -y -r 24 -i inputfile.%04d.png -vframes 100 -pix_fmt yuv422p \
    -pix_fmt yuv422p \
    -vf "scale=in_range=full:in_color_matrix=bt709:out_range=tv:out_color_matrix=bt709" 
    -c:v dnxhd -profile:v dnxhr_sq \
      -metadata project="MY PROJECT" \
      -metadata material_package_name="MY CLIP"  -timecode 01:00:20:00 \
      -f mxf_opatom \
      -color_range tv -colorspace bt709 -color_primaries bt709 -color_trc bt709 \
       outputfile.mxf
 ```

Typically you will want "MY CLIP" to match the outputfile, but its not necessary. Also note, that if you want a reel-name to also be on the clip that you will need to wrap the MXF file in an AAF (See below) to get the extra metadata imported.


 See [https://johnwarburton.net/blog/?p=50731](https://johnwarburton.net/blog/?p=50731)

 Also see [Avid Media Composer Workflow](EditorialWorkflow.html#avid-media-composer-workflows) for other workflows such as AAF creation.

## DNxHD Profiles

For example below is an example of DNxHD at 175Mbps at yuv422p10 at resolution 1920x1080.

<!---
name: test_dnxhd_profile
sources: 
- sourceimages/smptehdbars_10.dpx.yml
comparisontest:
   - testtype: idiff
     compare_image: ../sourceimages/smptehdbars_10_yuv422p10le.png
   - testtype: assertresults
     tests:
     - assert: less
       value: max_error
       less: 0.00195
-->
```
ffmpeg -y -r 24 -i inputfile.%04d.png -vframes 100 \
    -vf "in_range=full:in_color_matrix=bt709:out_range=tv:out_color_matrix=bt709" \
    -pix_fmt yuv422p10 -c:v dnxhd -b:v 175M \
     -vf "scale=in_color_matrix=bt709:out_color_matrix=bt709" \
     -color_primaries bt709 -color_range tv -color_trc bt709 -colorspace bt709 \
      outputfile.mov
```

Other combinations of resolution, bitrate and format are:

| Resolution | Bit Rate | Pix Format | Frame Rates |
|:----------|-----------:|:-----------|:-----------|
| 1920x1080p|  175M  |  yuv422p10 | 23.98, 24 |
| 1920x1080p|  185M  |  yuv422p10 | 25 |
| 1920x1080p|  365M  |  yuv422p10 | 50 |
| 1920x1080p|  440M  |  yuv422p10 | 59.94, 60 |
| 1920x1080p|  115M  |  yuv422p | 23.97, 24 |
| 1920x1080p|  120M  |  yuv422p | 25 |
| 1920x1080p|  145M  |  yuv422p | 29.97, 50 |
| 1920x1080p|  240M  |  yuv422p | 50 | 
| 1920x1080p|  290M  |  yuv422p | 59.94, 60 |
| 1920x1080p|  175M  |  yuv422p | 23.97, 24 |
| 1920x1080p|  185M  |  yuv422p | 25 |
| 1920x1080p|  220M  |  yuv422p | 29.97 | 
| 1920x1080p|  365M  |  yuv422p | 50 |
| 1920x1080p|  440M  |  yuv422p | 59.94, 60 |
| 1920x1080i|  185M  |  yuv422p10 | 25 |
| 1920x1080i|  220M  |  yuv422p10 | 29.97 |
| 1920x1080i|  120M  |  yuv422p | 25 |
| 1920x1080i|  145M  |  yuv422p | 29.97 |
| 1920x1080i|  185M  |  yuv422p | 25 |
| 1920x1080i|  220M  |  yuv422p | 29.97 |
| 1440x1080i|  120M  |  yuv422p | 25 |
| 1440x1080i|  145M  |  yuv422p | 29.97 |
| 1280x720p|  90M  |  yuv422p10 | 23.97, 24, 25 |
| 1280x720p|  180M  |  yuv422p10 | 50, 59.94, 60 |
| 1280x720p|  220M  |  yuv422p10 | 59.94, 60 |
| 1280x720p|  90M  |  yuv422p | 23.97, 24, 25 |
| 1280x720p|  110M  |  yuv422p | 29.97 |
| 1280x720p|  180M  |  yuv422p |  50 |
| 1280x720p|  220M  |  yuv422p | 59.94, 60 |
| 1280x720p|  60M  |  yuv422p | 23.97, 24, 25 |
| 1280x720p|  75M  |  yuv422p | 29.97 |
| 1280x720p|  120M  |  yuv422p | 50 |
| 1280x720p|  145M  |  yuv422p | 59.94, 60 |
| 1920x1080p|  36M  |  yuv422p | 23.97, 24, 25 |
| 1920x1080p|  45M  |  yuv422p | 29.97 |
| 1920x1080p|  75M  |  yuv422p | 50 |
| 1920x1080p|  90M  |  yuv422p | 59.94, 60 |
| 1920x1080p|  350M  |  yuv444p10, gbrp10 | 23.97, 24 |
| 1920x1080p|  390M  |  yuv444p10, gbrp10 | 25 |
| 1920x1080p|  440M  |  yuv444p10, gbrp10 | 29.97 |
| 1920x1080p|  730M  |  yuv444p10, gbrp10 | 50 |
| 1920x1080p|  880M  |  yuv444p10, gbrp10 | 59.94, 60 |
| 960x720p|  42M  |  yuv422p |
| 960x720p|  60M  |  yuv422p |
| 960x720p|  75M  |  yuv422p |
| 960x720p|  115M  |  yuv422p |
| 1440x1080p|  63M  |  yuv422p |
| 1440x1080p|  84M  |  yuv422p |
| 1440x1080p|  100M  |  yuv422p |
| 1440x1080p|  110M  |  yuv422p |
| 1440x1080i|  80M  |  yuv422p |
| 1440x1080i|  90M  |  yuv422p |
| 1440x1080i|  100M  |  yuv422p |
| 1440x1080i|  110M  |  yuv422p |

## See Also
   * https://dovidenko.com/2019/999/ffmpeg-dnxhd-dnxhr-mxf-proxies-and-optimized-media.html
   * https://askubuntu.com/questions/907398/how-to-convert-a-video-with-ffmpeg-into-the-dnxhd-dnxhr-format

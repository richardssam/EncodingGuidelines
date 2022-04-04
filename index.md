# FFMpeg encoding for VFX/Animation Production

This is a cheatsheet for encoding best practices for VFX/Animation production. For each section there are more detailed sections on why these settings are picked, and notes on what parameters you may want to change.

### Acknowledgements  <a name="Acknowledgements"></a>

This document is a result of feedback from many people, in particular I would like to thank Kevin Wheatley, Gates Roberg Clark, Rick Sayre, Wendy Heffner and J Schulte for their time and patience.  

## H264 Encoding from an image sequence for Web Review

If you are encoding from an image sequence (e.g. imagefile.0000.png imagefile.0001.png ...) to h264 using ffmpeg, we recommend:
```
ffmpeg -r 24 -start_number 1 -i inputfile.%04d.png -vf "scale=in_color_matrix=bt709:out_color_matrix=bt709" -vframes 100 -c:v libx264 -preset slower -pix_fmt yuv420p -color_range 1 -colorspace 1 -color_primaries 1 -color_trc 13 outputfile.mp4
```

| <!-- -->    | <!-- -->    |
| --- | --- |
| **-r 24**     | means 24 fps |
| **-start_number** 1 | The frame sequence starts from frame 1 (defaults to 0) |
**-i inputfile.%04d.png** | the file sequence will be padded to 4 digits, i.e. 0000, 0001, 0002, etc.
**[-frames:v](https://ffmpeg.org/ffmpeg.html#toc-Video-Options) 100** | is optional, but allows you to specify how many frames to encode, otherwise it will encode the entire frame range.
**-c:v libx264** | use the h264 encoding library (libx264)
**-preset slower** | a reasonably high quality preset, which will run slow, but not terribly slow.
**-pix_fmt yuv420p** | use yuv420 video format, which is typical for web playback. If you want a better quality for RV or other desktop tools use -pix_fmt yuv444p10le
**-color_range 1** | mp4 metadata - specifying color range as 16-235 (which is default for web playback).
**-colorspace 1** | mp4 metadata - specifying rec709 yuv color pixel format
**-color_primaries 1** | mp4 metadata - rec709 color gamut primaries
**-color_trc 13** | mp4 metadata color transfer = sRGB - See tests below.


**-vf "scale=in_color_matrix=bt709:out_color_matrix=bt709"** means use the sw-scale filter, setting:

| <!-- -->    | <!-- -->    |
| --- | --- |
| **in_color_matrix=rec709** | color space bt709 video coming in (normal for TV/Desktop video).|
| **out_color_matrix=rec709** | means color space bt709 video going out.  |

The combination of this and in_color_matrix will mean the color encoding will match the source media. If you are only adding one set of flags, this is the one, otherwise it will default to an output colorspace of bt601, which is a standard definition spec from the last century, and not suitable for sRGB or HD displays.

Separately, if you are converting from exr's in other colorspaces, **please use [OCIO](https://opencolorio.org/) to do the color space conversions.** [oiiotool](https://openimageio.readthedocs.io/en/latest/oiiotool.html) is an excellent open-source tool for this.

For more details see:
   * [H264 Encoding](Encoding.md#h264)
   * [YUV Conversion](ColorPreservation.md#yuv)
   * [Browser color issues](ColorPreservation.md#nclc)


## ProRes 422 encoding with ffmpeg.

Unlike h264 and DnXHD, Prores is a reverse-engineered codec. However, in many cases ffmpeg can produce adequate results. There are a number of codecs, we recommend the prores_ks one.

```
ffmpeg -r 24 -start_number 1 -i inputfile.%04d.png -vframes 100 -c:v prores_ks -profile:v 3 -qscale:v 9 -vf scale=in_color_matrix=bt709:out_color_matrix=bt709 -pix_fmt yuv422p10le outputfile.mov
```
| <!-- -->    | <!-- -->    |
| --- | --- |
| **-profile:v 3** | Prores profile |
| **-qscale:v 9** | Controls the output quality, lower numbers higher quality and larger file-size. *TODO Need to do testing with different values.* |
| **-pix_fmt yuv422p10le** | Convert to 10-bit YUV 422 |
| **-vendor apl0** | Treat the file as if it was created by the apple-Prores encoder (even though it isnt), helps some tools correctly read the quicktime |

For more details see:
   * [Prores](Encoding.md#prores)
   * [YUV Conversion](ColorPreservation.md#yuv)

## ProRes 4444 encoding with ffmpeg.

As above, but using 4444 (i.e. a color value for each pixel + an alpha)

```
ffmpeg -r 24 -start_number 1 -i inputfile.%04d.png -vframes 100 -c:v prores_ks -profile:v 4444 -qscale:v 9 -vf scale=in_color_matrix=bt709:out_color_matrix=bt709 -pix_fmt yuv444p10le outputfile.mov
```
| <!-- -->    | <!-- -->    |
| --- | --- |
| **-profile:v 4444** | Prores profile for 4444 |
| **-qscale:v 9** | Controls the output quality, lower numbers higher quality and larger file-size. *TODO Need to do testing with different values.*  |
| ** -pix_fmt yuv444p10le ** | Convert to 10-bit YUV 4444 |

For more details see:
   * [Prores](Encoding.md#prores)
   * [YUV Conversion](ColorPreservation.md#yuv)

### TV vs. Full range. <a name="tvfull"></a>
All the video formats typically do not use the full numeric range but instead the R', B', G' and Y' (luminance) channel have a nominal range of [16..235]  and the CB and CR channels have a nominal range of [16..240] with 128 as the neutral value. This frequently results in quantisation artifacts for 8-bit encoding (the standard for web playback).

TODO Get Quantization examples.

You can force the encoding to be full range using the libswscale library by using
```
-vf "scale=in_range=full:in_color_matrix=bt709:out_range=full:out_color_matrix=bt709"
```
Specifying *out_range=full* forces the output range, but you also need to set the NCLX tag:
```
-color_range 2
```
A full example encode would look like:
```
ffmpeg -y -loop 1 -i ../sourceimages/radialgrad.png -sws_flags spline+accurate_rnd+full_chroma_int -vf "scale=in_range=full:in_color_matrix=bt709:out_range=full:out_color_matrix=bt709" -c:v libx264 -t 5 -pix_fmt yuv420p -qscale:v 1 -color_range 2 -colorspace 1 -color_primaries 1 -color_trc 13 ./greyramp-fulltv/radialgrad-full.mp4
```
We have seen the full range encoding work across all browsers, and a number of players including RV.
TODO: Do additional testing across all players.

For more details see:
   * [Comparing full-range vs. tv range](https://richardssam.github.io/ffmpeg-tests/tests/greyramp-fulltv/compare.html)
   * [Encoding](Encoding.md#range)


### Encoding as RGB. <a name="rgbencode"></a>
You do not *have* to encode into YCrCb, h264 does support RGB encoding, which may be preferable in some situations.

Using the encoder:
```
-c:v libx264rgb
```
Will skip the conversion completely. Sadly this has no support in web browsers, but is supported by some players (e.g. RV). It is also limited to 8-bit.
TODO Check about 10-bit encoding.

For more details see:
   * [Comparing full-range vs. tv range](https://richardssam.github.io/ffmpeg-tests/tests/greyramp-fulltv/compare.html)
   * [Encoding](Encoding.md#range)
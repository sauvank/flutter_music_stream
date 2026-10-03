# DefaultRenderersFactory loads the extension by its class name.
-keep class androidx.media3.decoder.ffmpeg.FfmpegAudioRenderer { public <init>(...); }
-keepclasseswithmembernames class androidx.media3.decoder.ffmpeg.** { native <methods>; }

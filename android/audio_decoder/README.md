# Android software audio decoder

Media3 1.4.1 audio-only FFmpeg extension, matching `just_audio` 0.10.6.
The Java files and `ffmpeg_jni.cc` are unchanged upstream sources from
<https://github.com/androidx/media/tree/1.4.1/libraries/decoder_ffmpeg> (Apache 2.0;
see `LICENSE-MEDIA3`). No video renderer is included.

`scripts/build_android_audio_decoder.sh` downloads checksum-pinned FFmpeg 6.1.5
from <https://ffmpeg.org/releases/ffmpeg-6.1.5.tar.xz> and compiles AAC, ALAC and
FLAC only, with GPL/nonfree components disabled (LGPL 2.1 or later). Both license
texts are included in the APK's `assets/licenses/`. FFmpeg sources, configuration,
objects and binaries remain in `build/audio_decoder/native/`, not in Git. The
script and source archive allow rebuilding/relinking the shared library.

Builds require Linux/macOS, Bash, curl, make, tar, shasum and Android NDK
27.0.12077973. Gradle invokes the script automatically, including in release CI.
The first build takes longer; subsequent builds reuse Gradle outputs. Outputs
cover Android API 23+, ARMv7, ARM64 and x86_64, with 16 KB ELF segment alignment.

`android/enable_audio_decoder.gradle` compiles a generated copy of just_audio's
Java sources with extension renderers enabled and decoder fallback enabled.
The pub cache remains untouched. The native decoder keeps priority; Media3
selects FFmpeg for unsupported formats such as ALAC. Review this patch and the
Media3 version together whenever upgrading just_audio. The existing Flutter
player, queue, background controls and AudioTrack session remain in use.

Native playback tests (connected Android device/emulator):

```sh
cd android
./gradlew :audio_decoder:connectedDebugAndroidTest
```

Fixtures are synthetic 1.5-second stereo sine waves, generated with FFmpeg:

```sh
ffmpeg -f lavfi -i 'sine=frequency=440:duration=1.5:sample_rate=48000' -ac 2 -c:a aac -b:a 128k -fflags +bitexact -flags:a +bitexact -map_metadata -1 aac.m4a
ffmpeg -f lavfi -i 'sine=frequency=440:duration=1.5:sample_rate=48000' -ac 2 -c:a alac -sample_fmt s32p -fflags +bitexact -flags:a +bitexact -map_metadata -1 alac.m4a
```

Tests require playback to reach the end without errors and audio output to
advance. ALAC must explicitly use the FFmpeg renderer.

Physical-device playback still needs validation. In the current development
environment the emulator fails to start; compiling the instrumentation APK
does not replace running these tests on a device.

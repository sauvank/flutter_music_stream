#!/usr/bin/env bash
set -Eeuo pipefail

# Media3's audio-only FFmpeg extension, built from pinned LGPL sources.
# Arguments: NDK directory, build directory. No binaries enter the repository.
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ndk_dir="$1"
output_dir="$2"
mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"
version=6.1.5
archive_sha=05fbe9db1f5452a3605bb1d9bf91da9d4bb08162891692e4f172b58c49109412
archive="$output_dir/ffmpeg-$version.tar.xz"
if [[ ! -f "$archive" ]]; then
  curl --fail --location --retry 3 --connect-timeout 20 \
    "https://ffmpeg.org/releases/ffmpeg-$version.tar.xz" -o "$archive.part"
  mv "$archive.part" "$archive"
fi
actual_sha=$(shasum -a 256 "$archive" | cut -d ' ' -f 1)
[[ "$actual_sha" == "$archive_sha" ]] || { echo 'FFmpeg checksum mismatch' >&2; exit 1; }
if [[ ! -d "$output_dir/ffmpeg-$version" ]]; then
  tar -xf "$archive" -C "$output_dir"
fi
source_dir="$output_dir/ffmpeg-$version"
case "$(uname -s)" in
  Linux) host_tag=linux-x86_64 ;;
  Darwin) host_tag=darwin-x86_64 ;;
  *) echo 'Build the Android decoder on Linux or macOS.' >&2; exit 1 ;;
esac
toolchain="$ndk_dir/toolchains/llvm/prebuilt/$host_tag/bin"
jobs=${MUSICSTREAM_BUILD_JOBS:-4}
for abi in armeabi-v7a arm64-v8a x86_64; do
  case "$abi" in
    armeabi-v7a) arch=arm; target=armv7a-linux-androideabi; extra=(--cpu=armv7-a) ;;
    arm64-v8a) arch=aarch64; target=aarch64-linux-android; extra=(--cpu=armv8-a) ;;
    x86_64) arch=x86_64; target=x86_64-linux-android; extra=(--disable-x86asm) ;;
  esac
  work_dir="$output_dir/$abi"
  mkdir -p "$work_dir" "$output_dir/jniLibs/$abi"
  (
    cd "$work_dir"
    "$source_dir/configure" \
      --target-os=android --arch="$arch" --enable-cross-compile \
      --cc="$toolchain/${target}23-clang" \
      --cxx="$toolchain/${target}23-clang++" \
      --ar="$toolchain/llvm-ar" --nm="$toolchain/llvm-nm" \
      --ranlib="$toolchain/llvm-ranlib" --strip="$toolchain/llvm-strip" \
      --enable-pic --enable-small --enable-static --disable-shared \
      --disable-debug --disable-doc --disable-programs --disable-autodetect \
      --disable-everything --disable-network --disable-avdevice \
      --disable-avformat --disable-avfilter --disable-swscale --disable-postproc \
      --enable-swresample --enable-decoder=aac,alac,flac \
      "${extra[@]}" > configure.log
    make -j"$jobs" > build.log 2>&1
    "$toolchain/${target}23-clang++" -shared -fPIC -O2 -std=c++11 \
      -static-libstdc++ -I"$source_dir" -I"$work_dir" \
      "$repo_dir/android/audio_decoder/src/main/jni/ffmpeg_jni.cc" \
      -Wl,--start-group libavcodec/libavcodec.a libswresample/libswresample.a \
      libavutil/libavutil.a -Wl,--end-group -landroid -llog -lz -lm -latomic \
      -Wl,-z,max-page-size=16384 -Wl,-Bsymbolic -Wl,--exclude-libs,ALL \
      -o "$output_dir/jniLibs/$abi/libffmpegJNI.so"
    "$toolchain/llvm-strip" --strip-unneeded "$output_dir/jniLibs/$abi/libffmpegJNI.so"
  )
  echo "Built AAC/ALAC/FLAC decoder for $abi"
done

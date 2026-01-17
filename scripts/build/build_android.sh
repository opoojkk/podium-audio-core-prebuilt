#!/usr/bin/env bash
set -e

source "$(dirname "$0")/env.sh"

PLATFORM=android
ARCH=arm64-v8a
TARGET_DIR="$PLATFORM/$ARCH"
PREFIX="$OUT_DIR/$TARGET_DIR"

: "${ANDROID_NDK:?ANDROID_NDK not set}"

API=24
TOOLCHAIN="$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64"

export PATH="$TOOLCHAIN/bin:$PATH"
export CC="aarch64-linux-android${API}-clang"
export CXX="aarch64-linux-android${API}-clang++"
export AR=llvm-ar
export NM=llvm-nm
export STRIP=llvm-strip

mkdir -p "$BUILD_DIR/$TARGET_DIR"
mkdir -p "$PREFIX"

cd "$SRC_DIR"

./configure \
  --prefix="$PREFIX" \
  --target-os=android \
  --arch=aarch64 \
  --cpu=armv8-a \
  --enable-cross-compile \
  --cross-prefix=aarch64-linux-android- \
  --sysroot="$TOOLCHAIN/sysroot" \
  --enable-shared \
  --disable-static \
  --enable-pic \
  "${COMMON_CONFIG[@]}"

make -j"$(getconf _NPROCESSORS_ONLN)"
make install
make distclean

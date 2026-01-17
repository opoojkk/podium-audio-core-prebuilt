#!/usr/bin/env bash
set -e

source "$(dirname "$0")/env.sh"

PLATFORM=android
ARCH=arm64-v8a
TARGET_DIR="$PLATFORM/$ARCH"
PREFIX="$OUT_DIR/$TARGET_DIR"

ANDROID_NDK="${ANDROID_NDK:-${ANDROID_NDK_HOME:-}}"
: "${ANDROID_NDK:?ANDROID_NDK not set}"

API=24

PREBUILT_DIR="$ANDROID_NDK/toolchains/llvm/prebuilt"
if [ ! -d "$PREBUILT_DIR" ]; then
  echo "Invalid NDK llvm prebuilt dir: $PREBUILT_DIR"
  exit 1
fi

if [ -d "$PREBUILT_DIR/linux-x86_64" ]; then
  HOST_TAG="linux-x86_64"
elif [ -d "$PREBUILT_DIR/linux-x64" ]; then
  HOST_TAG="linux-x64"
else
  echo "No supported Linux toolchain found in:"
  ls "$PREBUILT_DIR"
  exit 1
fi

TOOLCHAIN="$PREBUILT_DIR/$HOST_TAG"
SYSROOT="$TOOLCHAIN/sysroot"
echo "Using NDK toolchain: $TOOLCHAIN"

export PATH="$TOOLCHAIN/bin:$PATH"

# 用“带 API 的 wrapper”走最稳的路径；同时显式用全路径避免被其他 clang 干扰
export CC="$TOOLCHAIN/bin/aarch64-linux-android${API}-clang"
export CXX="$TOOLCHAIN/bin/aarch64-linux-android${API}-clang++"
export AR="$TOOLCHAIN/bin/llvm-ar"
export NM="$TOOLCHAIN/bin/llvm-nm"
export STRIP="$TOOLCHAIN/bin/llvm-strip"

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
  --sysroot="$SYSROOT" \
  --extra-cflags="--sysroot=$SYSROOT" \
  --extra-ldflags="--sysroot=$SYSROOT" \
  --enable-shared \
  --disable-static \
  --enable-pic \
  "${COMMON_CONFIG[@]}" \
|| {
  echo ""
  echo "========== FFmpeg configure failed =========="
  echo "NDK: $ANDROID_NDK"
  echo "TOOLCHAIN: $TOOLCHAIN"
  echo "CC: $CC"
  echo "CXX: $CXX"
  echo ""
  echo "========== ffbuild/config.log (grep error|fatal|ld|clang) =========="
  # 只抓真正有用的行，避免被 ALL_COMPONENTS 淹没
  grep -nE "error:|fatal|ld(\.lld)?:|clang:|collect2:|cannot find|undefined reference" ffbuild/config.log || true
  echo ""
  echo "========== ffbuild/config.log (last 200 lines) =========="
  tail -n 200 ffbuild/config.log
  echo "============================================"
  exit 1
}

make -j"$(getconf _NPROCESSORS_ONLN)"
make install
make distclean

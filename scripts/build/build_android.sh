#!/usr/bin/env bash
set -e

source "$(dirname "$0")/env.sh"

PLATFORM=android
ARCH=armv8-a
TARGET_DIR="$PLATFORM/$ARCH"
PREFIX="$OUT_DIR/$TARGET_DIR"

# ---------- Resolve ANDROID_NDK ----------
ANDROID_NDK="${ANDROID_NDK:-${ANDROID_NDK_HOME:-}}"
: "${ANDROID_NDK:?ANDROID_NDK not set}"

API=24

# ---------- Resolve NDK toolchain ----------
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

echo "Using NDK toolchain: $TOOLCHAIN"

# ---------- Toolchain ----------
export PATH="$TOOLCHAIN/bin:$PATH"
export CC="aarch64-linux-android${API}-clang"
export CXX="aarch64-linux-android${API}-clang++"
export AR=llvm-ar
export NM=llvm-nm
export STRIP=llvm-strip

SYSROOT="$TOOLCHAIN/sysroot"

# ---------- Build dirs ----------
mkdir -p "$BUILD_DIR/$TARGET_DIR"
mkdir -p "$PREFIX"

cd "$SRC_DIR"

# ---------- Configure ----------
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
  "${COMMON_CONFIG[@]}"

# ---------- Build ----------
make -j"$(getconf _NPROCESSORS_ONLN)"
make install
make distclean

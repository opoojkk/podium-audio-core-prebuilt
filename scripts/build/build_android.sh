#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

# ------------------------------------------------------------------------------
# Args
# ------------------------------------------------------------------------------
ARCH="${1:?Usage: build_android.sh <arm64-v8a|armeabi-v7a|x86_64|x86>}"

PLATFORM=android
TARGET_DIR="$PLATFORM/$ARCH"
PREFIX="$OUT_DIR/$TARGET_DIR"

API=24

# ------------------------------------------------------------------------------
# Resolve ANDROID_NDK
# ------------------------------------------------------------------------------
ANDROID_NDK="${ANDROID_NDK:-${ANDROID_NDK_HOME:-}}"

if [ -z "$ANDROID_NDK" ]; then
  echo "Error: ANDROID_NDK or ANDROID_NDK_HOME must be set"
  echo "Available environment variables:"
  env | grep -i ndk || echo "  (none found)"
  exit 1
fi

if [ ! -d "$ANDROID_NDK" ]; then
  echo "Error: NDK directory not found: $ANDROID_NDK"
  exit 1
fi

echo "Using NDK: $ANDROID_NDK"

PREBUILT_DIR="$ANDROID_NDK/toolchains/llvm/prebuilt"

if [ -d "$PREBUILT_DIR/linux-x86_64" ]; then
  HOST_TAG="linux-x86_64"
elif [ -d "$PREBUILT_DIR/linux-x64" ]; then
  HOST_TAG="linux-x64"
else
  echo "Error: Unsupported NDK host, expected linux-x86_64 or linux-x64"
  exit 1
fi

TOOLCHAIN="$PREBUILT_DIR/$HOST_TAG"
SYSROOT="$TOOLCHAIN/sysroot"

export PATH="$TOOLCHAIN/bin:$PATH"

# ------------------------------------------------------------------------------
# Arch mapping
# ------------------------------------------------------------------------------
EXTRA_CFLAGS=""
EXTRA_LDFLAGS=""
EXTRA_ASFLAGS=""

case "$ARCH" in
  arm64-v8a)
    FF_ARCH=aarch64
    TRIPLE=aarch64-linux-android
    ;;
  armeabi-v7a)
    FF_ARCH=arm
    TRIPLE=armv7a-linux-androideabi
    EXTRA_CFLAGS="-march=armv7-a -mfloat-abi=softfp -mfpu=neon"
    ;;
  x86_64)
    FF_ARCH=x86_64
    TRIPLE=x86_64-linux-android
    EXTRA_ASFLAGS="-DPIC"
    ;;
  x86)
    FF_ARCH=x86
    TRIPLE=i686-linux-android
    EXTRA_CFLAGS="-fPIC -DPIC"
    EXTRA_LDFLAGS="-fPIC"
    EXTRA_ASFLAGS="-DPIC"
    # FFmpeg 7.0+ has fixed x86 PIC assembly issues
    ;;
  *)
    echo "Error: Unsupported arch: $ARCH"
    exit 1
    ;;
esac

export CC="$TOOLCHAIN/bin/${TRIPLE}${API}-clang"
export CXX="$TOOLCHAIN/bin/${TRIPLE}${API}-clang++"
export AR="$TOOLCHAIN/bin/llvm-ar"
export NM="$TOOLCHAIN/bin/llvm-nm"
export RANLIB="$TOOLCHAIN/bin/llvm-ranlib"
export STRIP="$TOOLCHAIN/bin/llvm-strip"

# Verify toolchain binaries exist
if [ ! -x "$CC" ]; then
  echo "Error: Compiler not found: $CC"
  exit 1
fi

# ------------------------------------------------------------------------------
# Build dirs
# ------------------------------------------------------------------------------
mkdir -p "$BUILD_DIR/$TARGET_DIR"
mkdir -p "$PREFIX"

cd "$SRC_DIR"

# ------------------------------------------------------------------------------
# Configure
# ------------------------------------------------------------------------------
./configure \
  --prefix="$PREFIX" \
  --target-os=android \
  --arch="$FF_ARCH" \
  --enable-cross-compile \
  --sysroot="$SYSROOT" \
  --cc="$CC" \
  --cxx="$CXX" \
  --ar="$AR" \
  --nm="$NM" \
  --ranlib="$RANLIB" \
  --strip="$STRIP" \
  --extra-cflags="--sysroot=$SYSROOT $EXTRA_CFLAGS" \
  --extra-ldflags="--sysroot=$SYSROOT $EXTRA_LDFLAGS" \
  --extra-asflags="$EXTRA_ASFLAGS" \
  --enable-shared \
  --disable-static \
  --enable-pic \
  --disable-programs \
  --disable-doc \
  "${COMMON_CONFIG[@]}"

# ------------------------------------------------------------------------------
# Build
# ------------------------------------------------------------------------------
make -j"$(nproc)"
make install
make distclean
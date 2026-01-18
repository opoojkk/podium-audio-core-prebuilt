#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

# ------------------------------------------------------------------------------
# Args
# ------------------------------------------------------------------------------
ARCH="${1:?Usage: build_linux.sh <x86_64|aarch64|armv7|i686>}"

PLATFORM=linux
TARGET_DIR="$PLATFORM/$ARCH"
PREFIX="$OUT_DIR/$TARGET_DIR"

# ------------------------------------------------------------------------------
# Arch mapping
# ------------------------------------------------------------------------------
EXTRA_CFLAGS=""
EXTRA_LDFLAGS=""
CROSS_PREFIX=""

case "$ARCH" in
  x86_64)
    # Native x86_64 build
    FF_ARCH=x86_64
    ;;
  aarch64)
    # ARM 64-bit (cross-compile if needed)
    FF_ARCH=aarch64
    CROSS_PREFIX="aarch64-linux-gnu-"
    EXTRA_CFLAGS="-march=armv8-a"
    ;;
  armv7)
    # ARM 32-bit with NEON
    FF_ARCH=arm
    CROSS_PREFIX="arm-linux-gnueabihf-"
    EXTRA_CFLAGS="-march=armv7-a -mfpu=neon -mfloat-abi=hard"
    ;;
  i686)
    # x86 32-bit
    FF_ARCH=x86
    EXTRA_CFLAGS="-m32"
    EXTRA_LDFLAGS="-m32"
    ;;
  *)
    echo "Error: Unsupported arch: $ARCH"
    exit 1
    ;;
esac

# ------------------------------------------------------------------------------
# Toolchain setup
# ------------------------------------------------------------------------------
if [ -n "$CROSS_PREFIX" ]; then
  # Cross-compilation
  export CC="${CROSS_PREFIX}gcc"
  export CXX="${CROSS_PREFIX}g++"
  export AR="${CROSS_PREFIX}ar"
  export NM="${CROSS_PREFIX}nm"
  export RANLIB="${CROSS_PREFIX}ranlib"
  export STRIP="${CROSS_PREFIX}strip"
  
  # Verify cross toolchain exists
  if ! command -v "$CC" >/dev/null 2>&1; then
    echo "Error: Cross toolchain not found: $CC"
    echo "Install with: sudo apt-get install gcc-${CROSS_PREFIX%-*}"
    exit 1
  fi
  
  ENABLE_CROSS="--enable-cross-compile"
else
  # Native compilation
  export CC=gcc
  export CXX=g++
  export AR=ar
  export NM=nm
  export RANLIB=ranlib
  export STRIP=strip
  
  ENABLE_CROSS=""
fi

# ------------------------------------------------------------------------------
# Prepare dirs
# ------------------------------------------------------------------------------
mkdir -p "$BUILD_DIR/$TARGET_DIR"
mkdir -p "$PREFIX"

cd "$SRC_DIR"

# ------------------------------------------------------------------------------
# Configure
# ------------------------------------------------------------------------------
./configure \
  --prefix="$PREFIX" \
  --target-os=linux \
  --arch="$FF_ARCH" \
  --cc="$CC" \
  --cxx="$CXX" \
  --ar="$AR" \
  --nm="$NM" \
  --ranlib="$RANLIB" \
  --strip="$STRIP" \
  $ENABLE_CROSS \
  --extra-cflags="$EXTRA_CFLAGS" \
  --extra-ldflags="$EXTRA_LDFLAGS" \
  --enable-shared \
  --disable-static \
  --enable-pic \
  --disable-programs \
  --disable-doc \
  --disable-debug \
  "${COMMON_CONFIG[@]}"

# ------------------------------------------------------------------------------
# Build
# ------------------------------------------------------------------------------
make -j"$(nproc)"
make install
make distclean
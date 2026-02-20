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
DISABLE_ASM=""

case "$ARCH" in
  x86_64)
    FF_ARCH=x86_64
    ;;
  aarch64)
    FF_ARCH=aarch64
    CROSS_PREFIX="aarch64-linux-gnu-"
    EXTRA_CFLAGS="-march=armv8-a"
    DISABLE_ASM="--disable-asm"
    ;;
  armv7)
    FF_ARCH=arm
    CROSS_PREFIX="arm-linux-gnueabihf-"
    EXTRA_CFLAGS="-march=armv7-a -mfpu=neon -mfloat-abi=hard"
    DISABLE_ASM="--disable-asm"
    ;;
  i686)
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
  export CC="${CROSS_PREFIX}gcc"
  export CXX="${CROSS_PREFIX}g++"
  export AR="${CROSS_PREFIX}ar"
  export NM="${CROSS_PREFIX}nm"
  export RANLIB="${CROSS_PREFIX}ranlib"
  export STRIP="${CROSS_PREFIX}strip"

  if ! command -v "$CC" >/dev/null 2>&1; then
    echo "Error: Cross toolchain not found: $CC"
    exit 1
  fi

  ENABLE_CROSS="--enable-cross-compile"
else
  export CC=gcc
  export CXX=g++
  export AR=ar
  export NM=nm
  export RANLIB=ranlib
  export STRIP=strip

  ENABLE_CROSS=""
fi

# ------------------------------------------------------------------------------
# Build OpenSSL for Linux (required for HTTPS/TLS protocol in FFmpeg)
# ------------------------------------------------------------------------------
OPENSSL_ARCH_PREFIX="$OPENSSL_OUT_DIR/linux/$ARCH"
if [ ! -f "$OPENSSL_ARCH_PREFIX/lib/libssl.a" ] && [ ! -f "$OPENSSL_ARCH_PREFIX/lib64/libssl.a" ]; then
  echo "OpenSSL not found for Linux $ARCH, building..."
  "$(dirname "$0")/build_openssl_linux.sh" "$ARCH"
fi

if [ -f "$OPENSSL_ARCH_PREFIX/lib/libssl.a" ] && [ -f "$OPENSSL_ARCH_PREFIX/lib/libcrypto.a" ]; then
  OPENSSL_LIB_DIR="$OPENSSL_ARCH_PREFIX/lib"
elif [ -f "$OPENSSL_ARCH_PREFIX/lib64/libssl.a" ] && [ -f "$OPENSSL_ARCH_PREFIX/lib64/libcrypto.a" ]; then
  OPENSSL_LIB_DIR="$OPENSSL_ARCH_PREFIX/lib64"
else
  echo "Error: OpenSSL build failed or artifacts missing at $OPENSSL_ARCH_PREFIX"
  find "$OPENSSL_ARCH_PREFIX" -maxdepth 4 -type f | sort || true
  exit 1
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
  --enable-openssl \
  $ENABLE_CROSS \
  $DISABLE_ASM \
  --extra-cflags="-I$OPENSSL_ARCH_PREFIX/include $EXTRA_CFLAGS" \
  --extra-ldflags="-L$OPENSSL_LIB_DIR -lssl -lcrypto $EXTRA_LDFLAGS" \
  --enable-shared \
  --disable-static \
  --enable-pic \
  --disable-programs \
  --disable-doc \
  --disable-debug \
  "${COMMON_CONFIG[@]}"

make -j"$(nproc)"
make install
make clean

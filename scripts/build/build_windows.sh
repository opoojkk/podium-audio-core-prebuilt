#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

ARCH="${1:?Usage: build_windows.sh <x64|x86>}"

PLATFORM=windows
TARGET_DIR="$PLATFORM/$ARCH"
PREFIX="$OUT_DIR/$TARGET_DIR"

# ------------------------------------------------------------------------------
# Arch mapping
# ------------------------------------------------------------------------------
case "$ARCH" in
  x64)
    FF_ARCH=x86_64
    CROSS=x86_64-w64-mingw32
    TOOLCHAIN_BIN=/mingw64/bin
    ;;
  x86)
    FF_ARCH=x86
    CROSS=i686-w64-mingw32
    TOOLCHAIN_BIN=/mingw32/bin
    ;;
  *)
    echo "Unsupported arch: $ARCH"
    exit 1
    ;;
esac

# ------------------------------------------------------------------------------
# Toolchain setup
# ------------------------------------------------------------------------------
export PATH="$TOOLCHAIN_BIN:$PATH"
export CC="$TOOLCHAIN_BIN/gcc"
export CXX="$TOOLCHAIN_BIN/g++"
export AR="$TOOLCHAIN_BIN/ar"
export NM="$TOOLCHAIN_BIN/nm"
export RANLIB="$TOOLCHAIN_BIN/ranlib"
export STRIP="$TOOLCHAIN_BIN/strip"
export LD="$TOOLCHAIN_BIN/ld"
export WINDRES="$TOOLCHAIN_BIN/windres"
export AS="$TOOLCHAIN_BIN/as"

# Verify toolchain availability
for tool in gcc ar nm ranlib strip; do
  if ! command -v "$TOOLCHAIN_BIN/$tool" >/dev/null 2>&1; then
    echo "Error: $tool not found in $TOOLCHAIN_BIN"
    exit 1
  fi
done

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
  --target-os=mingw32 \
  --arch="$FF_ARCH" \
  --cross-prefix="${CROSS}-" \
  --enable-cross-compile \
  --disable-shared \
  --enable-static \
  --disable-programs \
  --disable-doc \
  --disable-debug \
  --pkg-config=pkgconf \
  --pkg-config-flags="--static" \
  "${COMMON_CONFIG[@]}"

# ------------------------------------------------------------------------------
# Build
# ------------------------------------------------------------------------------
make -j"$(nproc)"
make install
make clean
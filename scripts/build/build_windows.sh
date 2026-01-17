#!/usr/bin/env bash
set -e
source "$(dirname "$0")/env.sh"

PLATFORM=windows
ARCH=x64
TARGET_DIR="$PLATFORM/$ARCH"
PREFIX="$OUT_DIR/$TARGET_DIR"

mkdir -p "$BUILD_DIR/$TARGET_DIR"
mkdir -p "$PREFIX"

cd "$SRC_DIR"

./configure \
  --prefix="$PREFIX" \
  --target-os=mingw64 \
  --arch=x86_64 \
  --enable-shared \
  --disable-static \
  "${COMMON_CONFIG[@]}"

make -j$(nproc)
make install
make distclean

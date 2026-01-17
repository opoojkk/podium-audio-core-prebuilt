#!/usr/bin/env bash
set -e

source "$(dirname "$0")/env.sh"

PLATFORM=windows
ARCH=x64
TARGET_DIR="$PLATFORM/$ARCH"
PREFIX="$OUT_DIR/$TARGET_DIR"

export CC=x86_64-w64-mingw32-gcc
export CXX=x86_64-w64-mingw32-g++
export AR=x86_64-w64-mingw32-ar
export NM=x86_64-w64-mingw32-nm
export STRIP=x86_64-w64-mingw32-strip

mkdir -p "$BUILD_DIR/$TARGET_DIR"
mkdir -p "$PREFIX"

cd "$SRC_DIR"

./configure \
  --prefix="$PREFIX" \
  --target-os=mingw64 \
  --arch=x86_64 \
  --enable-shared \
  --disable-static \
  --cross-prefix=x86_64-w64-mingw32- \
  "${COMMON_CONFIG[@]}"

make -j"$(getconf _NPROCESSORS_ONLN)"
make install
make distclean

#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Environment
# ------------------------------------------------------------------------------
source "$(dirname "$0")/env.sh"

PLATFORM=windows
ARCH=x64

TARGET_DIR="$PLATFORM/$ARCH"
PREFIX="$OUT_DIR/$TARGET_DIR"

# ------------------------------------------------------------------------------
# Sanity check
# ------------------------------------------------------------------------------
echo "[Sanity Check] toolchain"

command -v x86_64-w64-mingw32-gcc >/dev/null
command -v x86_64-w64-mingw32-ar >/dev/null
command -v x86_64-w64-mingw32-nm >/dev/null
command -v x86_64-w64-mingw32-ranlib >/dev/null
command -v make >/dev/null
command -v pkg-config >/dev/null

echo "[Sanity Check] toolchain OK"

# ------------------------------------------------------------------------------
# Export binutils explicitly (防止 PATH 异常)
# ------------------------------------------------------------------------------
export CC=x86_64-w64-mingw32-gcc
export AR=x86_64-w64-mingw32-ar
export NM="x86_64-w64-mingw32-nm -g"
export RANLIB=x86_64-w64-mingw32-ranlib
export STRIP=x86_64-w64-mingw32-strip

# ------------------------------------------------------------------------------
# Prepare directories
# ------------------------------------------------------------------------------
mkdir -p "$BUILD_DIR/$TARGET_DIR"
mkdir -p "$PREFIX"

cd "$SRC_DIR"

# ------------------------------------------------------------------------------
# Configure FFmpeg
# ------------------------------------------------------------------------------
./configure \
  --prefix="$PREFIX" \
  --target-os=mingw32 \
  --arch=x86_64 \
  --cross-prefix=x86_64-w64-mingw32- \
  --enable-shared \
  --disable-static \
  --disable-programs \
  --disable-doc \
  --disable-debug \
  "${COMMON_CONFIG[@]}"

# ------------------------------------------------------------------------------
# Build & Install
# ------------------------------------------------------------------------------
make -j"$(getconf _NPROCESSORS_ONLN)"
make install

# ------------------------------------------------------------------------------
# Cleanup (CI friendly)
# ------------------------------------------------------------------------------
make clean

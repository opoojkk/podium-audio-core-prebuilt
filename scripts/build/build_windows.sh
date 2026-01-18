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
# Export binutils explicitly
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
  --pkg-config=pkg-config \
  --pkg-config-flags="--static" \
  --extra-cflags="-O3" \
  --extra-ldflags="-static-libgcc -static-libstdc++" \
  "${COMMON_CONFIG[@]}"

# ------------------------------------------------------------------------------
# Build & Install
# ------------------------------------------------------------------------------
make -j"$(nproc)" V=1  # V=1 显示详细编译信息,便于调试
make install

# ------------------------------------------------------------------------------
# 修复 MinGW 导入库命名 (如果需要 .lib 格式)
# ------------------------------------------------------------------------------
if [ -d "$PREFIX/lib" ]; then
  cd "$PREFIX/lib"
  
  # 为 .dll.a 创建 .lib 符号链接(可选,用于兼容性)
  for f in lib*.dll.a; do
    if [ -f "$f" ]; then
      base="${f%.dll.a}"           # libavformat.dll.a -> libavformat
      name="${base#lib}"            # libavformat -> avformat
      ln -sf "$f" "${name}.lib"    # 创建 avformat.lib -> libavformat.dll.a
      echo "Created link: ${name}.lib -> $f"
    fi
  done
fi

# ------------------------------------------------------------------------------
# Cleanup (CI friendly)
# ------------------------------------------------------------------------------
cd "$SRC_DIR"
make clean
#!/usr/bin/env bash
set -e

source "$(dirname "$0")/env.sh"

PLATFORM=android
ARCH=arm64-v8a
TARGET_DIR="$PLATFORM/$ARCH"
PREFIX="$OUT_DIR/$TARGET_DIR"

# ---------- Resolve ANDROID_NDK ----------
ANDROID_NDK="${ANDROID_NDK:-${ANDROID_NDK_HOME:-}}"
: "${ANDROID_NDK:?ANDROID_NDK not set}"

API=24

# ---------- Resolve NDK toolchain ----------
PREBUILT_DIR="$ANDROID_NDK/toolchains/llvm/prebuilt"

if [ -d "$PREBUILT_DIR/linux-x86_64" ]; then
  HOST_TAG="linux-x86_64"
elif [ -d "$PREBUILT_DIR/linux-x64" ]; then
  HOST_TAG="linux-x64"
else
  echo "No supported Linux toolchain found in $PREBUILT_DIR"
  ls "$PREBUILT_DIR"
  exit 1
fi

TOOLCHAIN="$PREBUILT_DIR/$HOST_TAG"
SYSROOT="$TOOLCHAIN/sysroot"

echo "Using NDK toolchain: $TOOLCHAIN"

# ---------- Force NDK clang wrapper ----------
export PATH="$TOOLCHAIN/bin:$PATH"
export CC="$TOOLCHAIN/bin/aarch64-linux-android${API}-clang"
export CXX="$TOOLCHAIN/bin/aarch64-linux-android${API}-clang++"
export AR="$TOOLCHAIN/bin/llvm-ar"
export NM="$TOOLCHAIN/bin/llvm-nm"
export STRIP="$TOOLCHAIN/bin/llvm-strip"

# ---------- Build dirs ----------
mkdir -p "$BUILD_DIR/$TARGET_DIR"
mkdir -p "$PREFIX"

cd "$SRC_DIR"

# ---------- Configure (FINAL correct form) ----------
./configure \
  --prefix="$PREFIX" \
  --target-os=android \
  --arch=aarch64 \
  --enable-cross-compile \
  --cc="$CC" \
  --cxx="$CXX" \
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
  echo "CC: $CC"
  echo "SYSROOT: $SYSROOT"
  echo ""
  echo "========== ffbuild/config.log (errors) =========="
  grep -nE "Exec format error|error:|fatal|clang:|ld(\.lld)?:|cannot open|cannot find" ffbuild/config.log || true
  echo ""
  echo "========== ffbuild/config.log (last 200 lines) =========="
  tail -n 200 ffbuild/config.log
  echo "============================================"
  exit 1
}

# ---------- Build ----------
make -j"$(getconf _NPROCESSORS_ONLN)"
make install
make distclean

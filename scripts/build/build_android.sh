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

# ---------- Resolve NDK toolchain host tag ----------
HOST_OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
case "$HOST_OS" in
  linux)
    HOST_TAG="linux-x64"
    ;;
  darwin)
    HOST_TAG="darwin-x64"
    ;;
  *)
    echo "Unsupported host OS: $HOST_OS"
    exit 1
    ;;
esac

TOOLCHAIN="$ANDROID_NDK/toolchains/llvm/prebuilt/$HOST_TAG"

if [ ! -d "$TOOLCHAIN" ]; then
  echo "Invalid NDK toolchain path: $TOOLCHAIN"
  echo "Available toolchains:"
  ls "$ANDROID_NDK/toolchains/llvm/prebuilt"
  exit 1
fi

# ---------- Toolchain ----------
export PATH="$TOOLCHAIN/bin:$PATH"
export CC="aarch64-linux-android${API}-clang"
export CXX="aarch64-linux-android${API}-clang++"
export AR=llvm-ar
export NM=llvm-nm
export STRIP=llvm-strip

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
  --sysroot="$TOOLCHAIN/sysroot" \
  --enable-shared \
  --disable-static \
  --enable-pic \
  "${COMMON_CONFIG[@]}"

# ---------- Build ----------
make -j"$(getconf _NPROCESSORS_ONLN)"
make install
make distclean

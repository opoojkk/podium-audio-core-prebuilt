#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

ARCH="${1:?Usage: build_openssl_android.sh <arm64-v8a|armeabi-v7a|x86_64|x86>}"

ANDROID_NDK="${ANDROID_NDK:-${ANDROID_NDK_HOME:-}}"
if [ -z "$ANDROID_NDK" ]; then
  echo "Error: ANDROID_NDK or ANDROID_NDK_HOME must be set"
  exit 1
fi
if [ ! -d "$ANDROID_NDK" ]; then
  echo "Error: NDK directory not found: $ANDROID_NDK"
  exit 1
fi

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
API=24

case "$ARCH" in
  arm64-v8a)
    OPENSSL_TARGET="android-arm64"
    CC_BIN="aarch64-linux-android${API}-clang"
    ;;
  armeabi-v7a)
    OPENSSL_TARGET="android-arm"
    CC_BIN="armv7a-linux-androideabi${API}-clang"
    ;;
  x86_64)
    OPENSSL_TARGET="android-x86_64"
    CC_BIN="x86_64-linux-android${API}-clang"
    ;;
  x86)
    OPENSSL_TARGET="android-x86"
    CC_BIN="i686-linux-android${API}-clang"
    ;;
  *)
    echo "Error: Unsupported arch: $ARCH"
    exit 1
    ;;
esac

OPENSSL_ARCH_PREFIX="$OPENSSL_OUT_DIR/android/$ARCH"
if [ -f "$OPENSSL_ARCH_PREFIX/lib/libssl.a" ] && [ -f "$OPENSSL_ARCH_PREFIX/lib/libcrypto.a" ]; then
  echo "OpenSSL already built for $ARCH at $OPENSSL_ARCH_PREFIX"
  exit 0
fi

mkdir -p "$OPENSSL_SRC_DIR" "$OPENSSL_BUILD_DIR" "$OPENSSL_ARCH_PREFIX"

if [ ! -f "$OPENSSL_BUILD_DIR/$OPENSSL_TARBALL" ]; then
  echo "Downloading OpenSSL $OPENSSL_VERSION..."
  curl -L --retry 3 --fail "$OPENSSL_URL" -o "$OPENSSL_BUILD_DIR/$OPENSSL_TARBALL"
fi

if [ ! -d "$OPENSSL_SRC_DIR/openssl-$OPENSSL_VERSION" ]; then
  tar -xzf "$OPENSSL_BUILD_DIR/$OPENSSL_TARBALL" -C "$OPENSSL_SRC_DIR"
fi

cd "$OPENSSL_SRC_DIR/openssl-$OPENSSL_VERSION"

if [ -f Makefile ]; then
  make distclean || true
fi

export ANDROID_NDK_HOME="$ANDROID_NDK"
export PATH="$TOOLCHAIN/bin:$PATH"
export CC="$TOOLCHAIN/bin/$CC_BIN"

./Configure "$OPENSSL_TARGET" \
  -D__ANDROID_API__=$API \
  --prefix="$OPENSSL_ARCH_PREFIX" \
  --openssldir="$OPENSSL_ARCH_PREFIX/ssl" \
  no-shared no-tests

make -j"$(nproc)"
make install_sw

echo "OpenSSL built for $ARCH: $OPENSSL_ARCH_PREFIX"

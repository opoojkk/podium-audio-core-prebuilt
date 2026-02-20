#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

ARCH="${1:?Usage: build_openssl_ios.sh <arm64|arm64-simulator|x86_64-simulator>}"

IOS_MIN_VERSION=12.0

XCODE_PATH=$(xcode-select -p)
if [ ! -d "$XCODE_PATH" ]; then
  echo "Error: Xcode not found. Run: xcode-select --install"
  exit 1
fi

case "$ARCH" in
  arm64)
    SDK=iphoneos
    OPENSSL_TARGET=ios64-xcrun
    ARCH_FLAG="-arch arm64"
    ;;
  arm64-simulator)
    SDK=iphonesimulator
    OPENSSL_TARGET=iossimulator-xcrun
    ARCH_FLAG="-arch arm64"
    ;;
  x86_64-simulator)
    SDK=iphonesimulator
    OPENSSL_TARGET=iossimulator-xcrun
    ARCH_FLAG="-arch x86_64"
    ;;
  *)
    echo "Error: Unsupported arch: $ARCH"
    exit 1
    ;;
esac

SDK_PATH=$(xcrun --sdk "$SDK" --show-sdk-path)
if [ ! -d "$SDK_PATH" ]; then
  echo "Error: SDK not found: $SDK"
  exit 1
fi

OPENSSL_ARCH_PREFIX="$OPENSSL_OUT_DIR/ios/$ARCH"
if [ -f "$OPENSSL_ARCH_PREFIX/lib/libssl.a" ] && [ -f "$OPENSSL_ARCH_PREFIX/lib/libcrypto.a" ]; then
  echo "OpenSSL already built for iOS $ARCH at $OPENSSL_ARCH_PREFIX"
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

export CC="$(xcrun -sdk "$SDK" -f clang)"
export CFLAGS="$ARCH_FLAG -isysroot $SDK_PATH -mios-version-min=$IOS_MIN_VERSION"

./Configure "$OPENSSL_TARGET" \
  --prefix="$OPENSSL_ARCH_PREFIX" \
  --openssldir="$OPENSSL_ARCH_PREFIX/ssl" \
  no-shared no-tests no-asm

make -j"$(sysctl -n hw.ncpu)"
make install_sw

echo "OpenSSL built for iOS $ARCH: $OPENSSL_ARCH_PREFIX"

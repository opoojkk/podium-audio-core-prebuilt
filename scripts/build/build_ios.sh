#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

# ------------------------------------------------------------------------------
# Args
# ------------------------------------------------------------------------------
ARCH="${1:?Usage: build_ios.sh <arm64|arm64-simulator|x86_64-simulator>}"

PLATFORM=ios
TARGET_DIR="$PLATFORM/$ARCH"
PREFIX="$OUT_DIR/$TARGET_DIR"

# iOS deployment target
IOS_MIN_VERSION=12.0

# ------------------------------------------------------------------------------
# Resolve Xcode toolchain
# ------------------------------------------------------------------------------
XCODE_PATH=$(xcode-select -p)
if [ ! -d "$XCODE_PATH" ]; then
  echo "Error: Xcode not found. Run: xcode-select --install"
  exit 1
fi

echo "Using Xcode: $XCODE_PATH"

# ------------------------------------------------------------------------------
# Arch mapping
# ------------------------------------------------------------------------------
case "$ARCH" in
  arm64)
    # Physical device (iPhone/iPad)
    FF_ARCH=arm64
    SDK=iphoneos
    TARGET=arm-apple-darwin
    EXTRA_CFLAGS="-arch arm64"
    ;;
  arm64-simulator)
    # Simulator on Apple Silicon Mac
    FF_ARCH=arm64
    SDK=iphonesimulator
    TARGET=arm-apple-darwin
    EXTRA_CFLAGS="-arch arm64"
    ;;
  x86_64-simulator)
    # Simulator on Intel Mac
    FF_ARCH=x86_64
    SDK=iphonesimulator
    TARGET=x86_64-apple-darwin
    EXTRA_CFLAGS="-arch x86_64"
    ;;
  *)
    echo "Error: Unsupported arch: $ARCH"
    exit 1
    ;;
esac

# ------------------------------------------------------------------------------
# SDK paths
# ------------------------------------------------------------------------------
SDK_PATH=$(xcrun --sdk $SDK --show-sdk-path)
if [ ! -d "$SDK_PATH" ]; then
  echo "Error: SDK not found: $SDK"
  exit 1
fi

echo "Using SDK: $SDK_PATH"

# ------------------------------------------------------------------------------
# Toolchain setup
# ------------------------------------------------------------------------------
export CC="xcrun -sdk $SDK clang"
export CXX="xcrun -sdk $SDK clang++"
export AR="$(xcrun -sdk $SDK -f ar)"
export NM="$(xcrun -sdk $SDK -f nm)"
export RANLIB="$(xcrun -sdk $SDK -f ranlib)"
export STRIP="$(xcrun -sdk $SDK -f strip)"

COMMON_FLAGS="-isysroot $SDK_PATH -mios-version-min=$IOS_MIN_VERSION"
export CFLAGS="$COMMON_FLAGS $EXTRA_CFLAGS"
export CXXFLAGS="$COMMON_FLAGS $EXTRA_CFLAGS"
export LDFLAGS="$COMMON_FLAGS $EXTRA_CFLAGS"

# ------------------------------------------------------------------------------
# Build OpenSSL for iOS (required for HTTPS/TLS protocol in FFmpeg)
# ------------------------------------------------------------------------------
OPENSSL_ARCH_PREFIX="$OPENSSL_OUT_DIR/ios/$ARCH"
if [ ! -f "$OPENSSL_ARCH_PREFIX/lib/libssl.a" ] || [ ! -f "$OPENSSL_ARCH_PREFIX/lib/libcrypto.a" ]; then
  echo "OpenSSL not found for iOS $ARCH, building..."
  "$(dirname "$0")/build_openssl_ios.sh" "$ARCH"
fi

if [ ! -f "$OPENSSL_ARCH_PREFIX/lib/libssl.a" ] || [ ! -f "$OPENSSL_ARCH_PREFIX/lib/libcrypto.a" ]; then
  echo "Error: OpenSSL build failed or artifacts missing at $OPENSSL_ARCH_PREFIX"
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
  --target-os=darwin \
  --arch="$FF_ARCH" \
  --cc="$CC" \
  --cxx="$CXX" \
  --ar="$AR" \
  --nm="$NM" \
  --ranlib="$RANLIB" \
  --strip="$STRIP" \
  --enable-cross-compile \
  --enable-openssl \
  --extra-cflags="-I$OPENSSL_ARCH_PREFIX/include $EXTRA_CFLAGS" \
  --extra-ldflags="-L$OPENSSL_ARCH_PREFIX/lib -lssl -lcrypto" \
  --disable-shared \
  --enable-static \
  --enable-pic \
  --disable-programs \
  --disable-doc \
  --disable-debug \
  "${COMMON_CONFIG[@]}"

# ------------------------------------------------------------------------------
# Build
# ------------------------------------------------------------------------------
make -j"$(sysctl -n hw.ncpu)"
make install
make clean

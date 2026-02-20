#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

ARCH="${1:?Usage: build_openssl_linux.sh <x86_64|aarch64|armv7|i686>}"

OPENSSL_TARGET=""
CROSS_PREFIX=""
CC_CHECK=""
AR_CHECK=""
RANLIB_CHECK=""
EXTRA_CFLAGS=""
EXTRA_LDFLAGS=""

case "$ARCH" in
  x86_64)
    OPENSSL_TARGET=linux-x86_64
    CC_CHECK=gcc
    AR_CHECK=ar
    RANLIB_CHECK=ranlib
    ;;
  aarch64)
    OPENSSL_TARGET=linux-aarch64
    CROSS_PREFIX=aarch64-linux-gnu-
    CC_CHECK="${CROSS_PREFIX}gcc"
    AR_CHECK="${CROSS_PREFIX}ar"
    RANLIB_CHECK="${CROSS_PREFIX}ranlib"
    ;;
  armv7)
    OPENSSL_TARGET=linux-armv4
    CROSS_PREFIX=arm-linux-gnueabihf-
    CC_CHECK="${CROSS_PREFIX}gcc"
    AR_CHECK="${CROSS_PREFIX}ar"
    RANLIB_CHECK="${CROSS_PREFIX}ranlib"
    EXTRA_CFLAGS="-march=armv7-a -mfpu=neon -mfloat-abi=hard"
    ;;
  i686)
    OPENSSL_TARGET=linux-elf
    CC_CHECK=gcc
    AR_CHECK=ar
    RANLIB_CHECK=ranlib
    EXTRA_CFLAGS="-m32"
    EXTRA_LDFLAGS="-m32"
    ;;
  *)
    echo "Error: Unsupported arch: $ARCH"
    exit 1
    ;;
esac

for tool in "$CC_CHECK" "$AR_CHECK" "$RANLIB_CHECK"; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Error: tool not found: $tool"
    exit 1
  fi
done

OPENSSL_ARCH_PREFIX="$OPENSSL_OUT_DIR/linux/$ARCH"

have_lib() {
  [ -f "$OPENSSL_ARCH_PREFIX/lib/libssl.a" ] && [ -f "$OPENSSL_ARCH_PREFIX/lib/libcrypto.a" ]
}

have_lib64() {
  [ -f "$OPENSSL_ARCH_PREFIX/lib64/libssl.a" ] && [ -f "$OPENSSL_ARCH_PREFIX/lib64/libcrypto.a" ]
}

if have_lib; then
  echo "OpenSSL already built for Linux $ARCH at $OPENSSL_ARCH_PREFIX (lib)"
  exit 0
fi

if have_lib64; then
  echo "OpenSSL already built for Linux $ARCH at $OPENSSL_ARCH_PREFIX (lib64)"
  [ -e "$OPENSSL_ARCH_PREFIX/lib" ] || ln -s lib64 "$OPENSSL_ARCH_PREFIX/lib"
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

OPENSSL_CONFIG_ARGS=()
if [ -n "$CROSS_PREFIX" ]; then
  OPENSSL_CONFIG_ARGS+=("--cross-compile-prefix=${CROSS_PREFIX}")
fi

# Avoid leaking prefixed AR/RANLIB from parent env (e.g. build_linux.sh).
# OpenSSL will prepend CROSS_PREFIX to these tool names.
export CC=gcc
export AR=ar
export RANLIB=ranlib
export NM=nm

./Configure "$OPENSSL_TARGET" \
  --prefix="$OPENSSL_ARCH_PREFIX" \
  --openssldir="$OPENSSL_ARCH_PREFIX/ssl" \
  --libdir=lib \
  "${OPENSSL_CONFIG_ARGS[@]}" \
  no-shared no-tests no-asm \
  ${EXTRA_CFLAGS:+-fPIC $EXTRA_CFLAGS} \
  ${EXTRA_LDFLAGS:+$EXTRA_LDFLAGS}

make -j"$(nproc)"
make install_sw

if ! have_lib && have_lib64; then
  [ -e "$OPENSSL_ARCH_PREFIX/lib" ] || ln -s lib64 "$OPENSSL_ARCH_PREFIX/lib"
fi

if ! have_lib; then
  echo "Error: OpenSSL artifacts missing after install for ARCH=$ARCH"
  echo "Expected: $OPENSSL_ARCH_PREFIX/lib/libssl.a and libcrypto.a"
  echo "Actual files under $OPENSSL_ARCH_PREFIX:"
  find "$OPENSSL_ARCH_PREFIX" -maxdepth 4 -type f | sort || true
  exit 1
fi

echo "OpenSSL built for Linux $ARCH: $OPENSSL_ARCH_PREFIX"

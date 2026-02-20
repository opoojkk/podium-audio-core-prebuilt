#!/usr/bin/env bash
set -e

# ===== FFmpeg version =====
FFMPEG_VERSION=7.0
# Use GitHub mirror for better reliability
FFMPEG_GIT=https://github.com/FFmpeg/FFmpeg.git

# ===== OpenSSL version (for Android HTTPS/TLS support) =====
OPENSSL_VERSION=3.3.2
OPENSSL_TARBALL="openssl-$OPENSSL_VERSION.tar.gz"
OPENSSL_URL="https://github.com/openssl/openssl/releases/download/openssl-$OPENSSL_VERSION/$OPENSSL_TARBALL"

# ===== Project root =====
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

# ===== Directories =====
SRC_DIR="$ROOT_DIR/.ffmpeg-src"
BUILD_DIR="$ROOT_DIR/.ffmpeg-build"
OUT_DIR="$ROOT_DIR/output"
OPENSSL_SRC_DIR="$ROOT_DIR/.openssl-src"
OPENSSL_BUILD_DIR="$ROOT_DIR/.openssl-build"
OPENSSL_OUT_DIR="$ROOT_DIR/.openssl-out"

# ===== Build options =====
# Keep codec/container support broad (default FFmpeg behavior),
# while explicitly ensuring remote streaming protocols are available.
COMMON_CONFIG=(
  --disable-programs
  --disable-doc
  --disable-avdevice
  --disable-avfilter
  --enable-avformat
  --enable-avcodec
  --enable-avutil
  --enable-swresample
  --disable-vulkan
  --disable-hwaccels
  --disable-videotoolbox
  --disable-audiotoolbox

  --enable-network
  --enable-protocol=file
  --enable-protocol=http
  --enable-protocol=https
  --enable-protocol=tcp
  --enable-protocol=tls
)

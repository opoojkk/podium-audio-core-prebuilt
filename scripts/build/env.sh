#!/usr/bin/env bash
set -e

# ===== FFmpeg version =====
FFMPEG_VERSION=6.1
FFMPEG_GIT=https://git.ffmpeg.org/ffmpeg.git

# ===== Project root =====
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

# ===== Directories =====
SRC_DIR="$ROOT_DIR/.ffmpeg-src"
BUILD_DIR="$ROOT_DIR/.ffmpeg-build"
OUT_DIR="$ROOT_DIR/output"

# ===== Build options =====
COMMON_CONFIG=(
  --disable-programs
  --disable-doc
  --disable-avdevice
  --disable-avfilter
  --enable-avformat
  --enable-avcodec
  --enable-avutil
  --enable-swresample
)

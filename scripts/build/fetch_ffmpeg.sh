#!/usr/bin/env bash
set -e

source "$(dirname "$0")/env.sh"

if [ -d "$SRC_DIR/.git" ]; then
  echo "FFmpeg source already exists, updating..."
  cd "$SRC_DIR"
  git fetch --tags
  git reset --hard
  git checkout "n$FFMPEG_VERSION"
else
  echo "Cloning FFmpeg $FFMPEG_VERSION..."
  git clone --depth 1 --branch "n$FFMPEG_VERSION" "$FFMPEG_GIT" "$SRC_DIR"
fi

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
  echo "Cloning FFmpeg $FFMPEG_VERSION from $FFMPEG_GIT..."
  
  # Retry logic for flaky network connections
  max_retries=3
  retry_count=0
  
  while [ $retry_count -lt $max_retries ]; do
    if git clone --depth 1 --branch "n$FFMPEG_VERSION" "$FFMPEG_GIT" "$SRC_DIR"; then
      echo "Clone successful"
      break
    else
      retry_count=$((retry_count + 1))
      if [ $retry_count -lt $max_retries ]; then
        echo "Clone failed, retrying ($retry_count/$max_retries)..."
        sleep 5
        rm -rf "$SRC_DIR"
      else
        echo "Clone failed after $max_retries attempts"
        exit 1
      fi
    fi
  done
fi
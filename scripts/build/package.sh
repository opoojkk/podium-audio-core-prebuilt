#!/usr/bin/env bash
set -e

source "$(dirname "$0")/env.sh"

cd "$OUT_DIR"

find . -type d -name "include" | while read -r include_path; do
  dir_to_package=$(dirname "$include_path")
  dir_to_package=${dir_to_package#./}
  archive_name=$(echo "$dir_to_package" | tr '/' '-')

  echo "Packaging $dir_to_package as ffmpeg-$FFMPEG_VERSION-$archive_name.tar.gz..."
  tar \
    --no-same-owner \
    --no-same-permissions \
    -czf "ffmpeg-$FFMPEG_VERSION-$archive_name.tar.gz" \
    "$dir_to_package"
done

sha256sum *.tar.gz > checksums.txt

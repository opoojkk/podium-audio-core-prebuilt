#!/usr/bin/env bash
set -e
source "$(dirname "$0")/env.sh"

cd "$OUT_DIR"

# Find all leaf directories that contain an 'include' folder (standard FFmpeg install structure)
find . -type d -name "include" | while read -r include_path; do
  # Get the parent directory of 'include'
  dir_to_package=$(dirname "$include_path")
  # Remove './' prefix if present
  dir_to_package=${dir_to_package#./}
  
  # Create a clean filename (e.g., windows/x64 -> windows-x64)
  archive_name=$(echo "$dir_to_package" | tr '/' '-')
  
  echo "Packaging $dir_to_package as ffmpeg-$FFMPEG_VERSION-$archive_name.tar.gz..."
  tar -czf "ffmpeg-$FFMPEG_VERSION-$archive_name.tar.gz" "$dir_to_package"
done

# Generate checksums
sha256sum *.tar.gz > checksums.txt

# Podium Audio Core Prebuilt

This repository provides pre-built FFmpeg binaries specifically for the **Podium Audio Core** project, organized and optimized for consumption in Kotlin Multiplatform (KMP) environments.

## Purpose

- **Isolation**: Keep FFmpeg build complexity out of the main application repository.
- **Reproducibility**: Use consistent build scripts and fixed versions.
- **Speed**: Consume pre-built binaries instead of building from source in every CI run.

## Supported Platforms

- **Windows**: `windows/x64`
- **Android**: `android/arm64-v8a`

## How to Trigger a Build

Builds are automatically triggered when a tag matching `ffmpeg-*` is pushed.

```bash
git tag ffmpeg-6.1-podium.1
git push origin ffmpeg-6.1-podium.1
```

## Repository Structure

- `scripts/build/`: Bash scripts for fetching, building, and packaging FFmpeg.
- `.github/workflows/`: GitHub Actions configuration.
- `output/`: (Local only) Destination for build products, organized by `platform/arch`.

## Usage in Consumer Projects

1. Download the desired release artifact (e.g., `ffmpeg-6.1-windows-x64.tar.gz`).
2. Extract to your project's `native/third_party/ffmpeg/` directory.
   - It will create a structure like `windows/x64/bin/...` or `android/arm64-v8a/lib/...`.
3. Reference the binaries in your build system.

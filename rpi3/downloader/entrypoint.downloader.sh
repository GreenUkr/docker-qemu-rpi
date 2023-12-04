#!/bin/sh

set -e

SD_BASE_NAME="sd_base.img"

# IMAGE_URL will be get from downloader.env
SHA256_URL="$IMAGE_URL.sha256"

IMAGE_NAME=$(basename "$IMAGE_URL")
SHA256_NAME="$IMAGE_NAME.sha256"

download_file() {
  local url="$1"
  local name="$2"

  curl -z "$name" -o "$name" "$url" \
    || { echo "Error: Failed to download file $name"; exit 1; } \
    | [ -s "$name" ] \
      || { echo "Error: Downloaded file $name is empty"; exit 1; }

  echo "File downloaded successfully: $name"
}

decompress_image() {
  local input_file="$1"
  local output_file="$2"

  if [ -s "$output_file" ]; then
    echo "Skipping decompression. Output file already exists and is non-zero: $output_file"
    return 0
  fi

  if file "$input_file" | grep -qi "xz compressed data"; then
    # Decompress XZ-compressed image
    echo "Decompressing XZ-compressed image: $input_file"
    xz -dk "$input_file" -c > "$output_file"
  elif file "$input_file" | grep -qi "gzip compressed data"; then
    # Decompress GZIP-compressed image
    echo "Decompressing GZIP-compressed image: $input_file"
    gzip -dk "$input_file" -c > "$output_file"
  else
    echo "Error: Unsupported compression type for image: $input_file"
    exit 1
  fi

  echo "Image decompressed successfully: $output_file"
}

download_file "$IMAGE_URL" "$IMAGE_NAME"
download_file "$SHA256_URL" "$SHA256_NAME"

# Verify the SHA256 checksum
echo "Verifying checksum..."
sha256sum -c "$SHA256_NAME"

# Decompress the image
decompress_image "$IMAGE_NAME" "$SD_BASE_NAME"

echo "All files downloaded and decompressed successfully!"

exec "$@"
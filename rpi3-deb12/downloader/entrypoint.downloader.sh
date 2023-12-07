#!/bin/sh

download_file() {
  local url=$1
  local output_path=$2
  local wget_options=" --progress=dot:giga --no-check-certificate"

  if [ -f "$output_path" ]; then
    echo "File $(basename "$output_path") already exists. Skipping download."
  else
    if wget $wget_options -O "$output_path" "$url"; then
      echo "$output_path downloaded successfully."
    else
      echo "Error: Failed to download $output_path."
      exit 1
    fi
  fi
}

verify_checksum() {
  local file_path=$1
  local checksum_file=$2

  sha256sum -c "$checksum_file" >/dev/null 2>&1
  SHA256_STATUS=$?
  if [ $SHA256_STATUS -ne 0 ]; then
    echo "Error: SHA256 checksum verification failed for $file_path."
    return 1
  else
    echo "SHA256 checksum verified for $file_path."
    return 0
  fi
}

# Extracting the file name from the provided URL
FILE_NAME=$(basename "$IMAGE_URL")

# Setting the local file paths for the image and SHA256 file
LOCAL_FILE_PATH="/data/$FILE_NAME"
SHA256_FILE_PATH="$LOCAL_FILE_PATH.sha256"

# Download the image file
download_file "$IMAGE_URL" "$LOCAL_FILE_PATH"

# Download the SHA256 file
download_file "$IMAGE_URL.sha256" "$SHA256_FILE_PATH"

# Verify checksum of the image file
if verify_checksum "$LOCAL_FILE_PATH" "$SHA256_FILE_PATH"; then
  # If verification is successful, continue
  echo "Checksum verification successful."
else
  # If verification fails, redownload the image file
  echo "SHA256 checksum verification failed. Redownloading the file."
  rm -f "$LOCAL_FILE_PATH"
  download_file "$IMAGE_URL" "$LOCAL_FILE_PATH"

  # Verify checksum of the redownloaded image file
  verify_checksum "$LOCAL_FILE_PATH" "$SHA256_FILE_PATH"
fi

# Execute the provided command or entrypoint
exec "$@"

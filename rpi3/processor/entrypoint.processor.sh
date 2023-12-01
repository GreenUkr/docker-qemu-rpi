#!/bin/sh

# Extracting the file name from the provided URL
FILE_NAME=$(basename "$IMAGE_URL")

# Check if the compressed file exists
COMPRESSED_FILE="/data/$FILE_NAME"
UNCOMPRESSED_FILE="/data/${FILE_NAME%.*}"
SD_IMAGE_PATH="/data/sd.img"

cd /data

# Check if the uncompressed file already exists
if [ -f "$UNCOMPRESSED_FILE" ]; then
  echo "Uncompressed file $UNCOMPRESSED_FILE already exists. Skipping decompression."
else
  if [ -f "$COMPRESSED_FILE" ]; then
    echo "Start uncompressing $COMPRESSED_FILE"
    # Determine the compression type based on file extension and uncompress accordingly
    case "$COMPRESSED_FILE" in
      *.xz)
        xz -d -k "$COMPRESSED_FILE" ;;
      *.gz)
        gzip -d -k "$COMPRESSED_FILE" ;;
      *)
        echo "Error: Unsupported compression format."
        exit 1 ;;
    esac

    echo "File $COMPRESSED_FILE uncompressed to $UNCOMPRESSED_FILE."
  else
    echo "Error: Compressed file $COMPRESSED_FILE not found."
    exit 1
  fi
fi

if [ ! -f "$SD_IMAGE_PATH" ]; then
  cp "$UNCOMPRESSED_FILE" "$SD_IMAGE_PATH"
  echo "SD file $SD_IMAGE_PATH created."
  # Resize the image to next power of two finding the most significant bit (add 2 more to incrise by 4)
  CURRENT_SIZE=$(stat -c %s "$SD_IMAGE_PATH" || stat -f %z "$SD_IMAGE_PATH")
  NEXT_POWER_OF_TWO=$(awk -v size="$CURRENT_SIZE" 'BEGIN { pos=0; while ((2^pos) < size) pos++; print 2^(pos+2) }')
  echo "Resizing $SD_IMAGE_PATH from $CURRENT_SIZE to $NEXT_POWER_OF_TWO"
  qemu-img resize "$SD_IMAGE_PATH" -f raw "$NEXT_POWER_OF_TWO"
  
  # Calculate the offset in bytes
  OFFSET=$(fdisk -lu "$SD_IMAGE_PATH" | awk '/^Units:/ {sector_size=$8} /FAT32 \(LBA\)/ { if ($4 == "*") print $5 * sector_size; else print $4  * sector_size}')
  echo "Offset of FAT32 partition is $OFFSET"
  
  if [ -z "$OFFSET" ]; then \
      echo "Error: FAT32 not found in disk image" && \
      rm -f "$SD_IMAGE_PATH" && \
      exit 1; \
  fi

# Set up SSH
  # RPI changed default password policy, so we create an user 'admin' with password 'admin'
  touch /tmp/ssh && \
  # echo 'admin:$6$pvZPqbeuY5TihO1X$jVl076HgF6cnu7QyRxfkcLBfEvwlWP3QHyictpoHD6kLMw3vy9lGZyRgYaD.VWGKiLnd6445B/nqIYRLWXwhv/' | tee /tmp/userconf
  echo "$ADMIN_USER":"$ADMIN_PASSWORD" | tee /tmp/userconf

  # Copy kernel and device tree from SD card
  mcopy -i "$SD_IMAGE_PATH@@$OFFSET" ::/$DTB_FILE ::/$KERNEL_FILE /data/ && \
  # Copy ssh and userconf to SD card
  mcopy -i "$SD_IMAGE_PATH@@$OFFSET" /tmp/ssh /tmp/userconf ::/
  MCOPY_STATUS=$?
  
  if [ $MCOPY_STATUS -ne 0 ]; then \
    echo "Error: Failed to copy kernel and device tree from SD card." && \
    rm -f "$SD_IMAGE_PATH" && \
    exit 1; \
  else \
    echo "Kernel and device tree copied from SD card."
  fi  
  
else
  echo "SD file $SD_IMAGE_PATH already exists. Skipping processing."
fi

exec "$@"

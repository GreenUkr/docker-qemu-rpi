#!/bin/sh

# Extracting the file name from the provided URL
FILE_NAME=$(basename "$IMAGE_URL")

# Check if the compressed file exists
COMP_FILE="$FILE_NAME"
UNCOMP_FILE="${FILE_NAME%.*}"
SD_RAW_IMAGE="sd.img"
SD_IMAGE="sd.qcow2"

# Check if the uncompressed file already exists
if [ -f "$UNCOMP_FILE" ]; then
  echo "Uncompressed file $UNCOMP_FILE already exists. Skipping decompression."
else
  if [ -f "$COMP_FILE" ]; then
    echo "Start uncompressing $COMP_FILE"
    # Determine the compression type based on file extension and uncompress accordingly
    case "$COMP_FILE" in
      *.xz)
        xz -d -k "$COMP_FILE" ;;
      *.gz)
        gzip -d -k "$COMP_FILE" ;;
      *)
        echo "Error: Unsupported compression format."
        exit 1 ;;
    esac

    echo "File $COMP_FILE uncompressed to $UNCOMP_FILE."
  else
    echo "Error: Compressed file $COMP_FILE not found."
    exit 1
  fi
fi

if [ ! -f "$SD_IMAGE" ]; then
  cp "$UNCOMP_FILE" "$SD_RAW_IMAGE"
  echo "Temporary SD file $SD_RAW_IMAGE created."

  # Calculate the offset in bytes
  OFFSET=$(fdisk -lu "$SD_RAW_IMAGE" | awk '/^Units:/ {sector_size=$8} /FAT32 \(LBA\)/ { if ($4 == "*") print $5 * sector_size; else print $4  * sector_size}')
  echo "Offset of FAT32 partition is $OFFSET"
  
  if [ -z "$OFFSET" ]; then \
      echo "Error: FAT32 not found in disk image" && \
      rm -f "$SD_RAW_IMAGE" && \
      exit 1; \
  fi

  # Set up SSH
  # RPI changed default password policy, so we create an user 'admin' with password 'admin'
  touch /tmp/ssh && \
  # echo 'admin:$6$pvZPqbeuY5TihO1X$jVl076HgF6cnu7QyRxfkcLBfEvwlWP3QHyictpoHD6kLMw3vy9lGZyRgYaD.VWGKiLnd6445B/nqIYRLWXwhv/' | tee /tmp/userconf
  echo "$ADMIN_USER":"$ADMIN_PASSWORD" | tee /tmp/userconf

  # Copy kernel and device tree from SD card
  mcopy -i "$SD_RAW_IMAGE@@$OFFSET" ::/$DTB_FILE ::/$KERNEL_FILE /data/ && \
  # Copy ssh and userconf to SD card
  mcopy -i "$SD_RAW_IMAGE@@$OFFSET" /tmp/ssh /tmp/userconf ::/
  MCOPY_STATUS=$?
  
  if [ $MCOPY_STATUS -ne 0 ]; then \
    echo "Error: Failed to copy kernel and device tree from SD card." && \
    rm -f "$SD_RAW_IMAGE" && \
    exit 1; \
  else \
    echo "Kernel and device tree copied from SD card."
  fi  

  echo "Converting $SD_RAW_IMAGE to $SD_IMAGE"
  qemu-img convert -f raw -O qcow2 $SD_RAW_IMAGE $SD_IMAGE       

  rm -f "$SD_RAW_IMAGE"
  echo "SD file $SD_RAW_IMAGE removed."
  # Resize the image to next power of two finding the most significant bit (add 2 more to incrise by 4)
  # CURRENT_SIZE=$(stat -c %s "$SD_IMAGE" || stat -f %z "$SD_IMAGE")
  # NEXT_POWER_OF_TWO=$(awk -v size="$CURRENT_SIZE" 'BEGIN { pos=0; while ((2^pos) < size) pos++; print 2^(pos+2) }')
  # echo "Resizing $SD_IMAGE from $CURRENT_SIZE to $NEXT_POWER_OF_TWO"
  # qemu-img resize "$SD_IMAGE" -f raw "$NEXT_POWER_OF_TWO"
  echo "Resizing $SD_IMAGE to $SD_SIZE"
  qemu-img resize "$SD_IMAGE" -f qcow2 "${SD_SIZE}G"
else
  echo "SD file $SD_IMAGE already exists. Skipping processing."
fi

echo "Check SD image $SD_IMAGE info"
qemu-img info "$SD_IMAGE"
  

exec "$@"
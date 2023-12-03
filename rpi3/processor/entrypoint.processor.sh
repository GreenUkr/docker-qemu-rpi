#!/bin/sh

set -eo pipefail

SD_BASE_NAME="sd_base.img"
SD_RAW_NAME="sd.img"
SD_NAME="sd.qcow2"

# Function to check for the FAT32 partition and return the offset
check_fat32_partition() {
  local sd_info startsector offset
  
  # Get information about the SD image using the 'file' command
  sd_info=$(file "$SD_BASE_NAME")

  # Check if the SD image contains a FAT32 partition (ID=0xc)
  if echo "$sd_info" | grep -qi "ID=0xc"; then
    # Extract the start sector of the FAT32 partition
    startsector=$(echo "$sd_info" | awk -F';' '/ID=0xc/ { gsub(",", "\n", $0); print $0 }' \
        | awk '/startsector/ { print $2; exit }')

    # Calculate the offset in bytes based on the start sector (assuming sector size is 512 bytes)
    offset=$((startsector * 512))

    # Create a raw copy of the SD image
    cp "$SD_BASE_NAME" "$SD_RAW_NAME"

    # Return the offset value
    echo $offset
  else
    # Exit if no FAT32 partition is found
    echo "Error: No FAT32 partition in SD image $SD_RAW_NAME"
    exit 1
  fi
}

# Main code
if [ ! -f "$SD_NAME" ]; then
  # Call the function to check for the FAT32 partition and get the offset
  offset=$(check_fat32_partition 2>/dev/null)

  # Display the offset if a FAT32 partition is found
  echo "FAT32 partition found. Offset: $offset"

  # Set up SSH
  # RPI changed default password policy, so we create an user 'admin' with password 'admin'
  touch /tmp/ssh && \
  # echo 'admin:$6$pvZPqbeuY5TihO1X$jVl076HgF6cnu7QyRxfkcLBfEvwlWP3QHyictpoHD6kLMw3vy9lGZyRgYaD.VWGKiLnd6445B/nqIYRLWXwhv/' | tee /tmp/userconf
  echo "$ADMIN_USER":"$ADMIN_PASSWORD" | tee /tmp/userconf

  # Copy kernel and device tree from SD card
  mcopy -i "$SD_RAW_NAME@@$offset" ::/$DTB_FILE ::/$KERNEL_FILE /data/ && \
  # Copy ssh and userconf to SD card
  mcopy -i "$SD_RAW_NAME@@$offset" /tmp/ssh /tmp/userconf ::/
  # Check if the mcopy was successful
  if [ $? -eq 0 ]; then
    echo "Kernel and device tree copied from $SD_RAW_NAME"
  else
    echo "Error: Failed to copy kernel and device tree from SD card."
    echo "Removing temp resources..."
    rm -f $SD_RAW_NAME $DTB_FILE $KERNEL_FILE
    exit 1
  fi  

  echo "Converting $SD_RAW_NAME to $SD_NAME"
  qemu-img convert -f raw -O qcow2 $SD_RAW_NAME $SD_NAME
  # Check if the conversion was successful
  if [ $? -eq 0 ]; then
    echo "Conversion successful. Removing source image..."
    # Remove the source image if the conversion was successful
    rm -f "$SD_RAW_NAME"
    echo "Temp $SD_RAW_NAME removed."
  else
    echo "Error: Conversion failed. Source image not removed."
    exit 1
  fi  
  # Resize the image to next power of two finding the most significant bit (add 2 more to incrise by 4)
  echo "Resizing $SD_NAME to $SD_SIZE ..."
  qemu-img resize "$SD_NAME" -f qcow2 "${SD_SIZE}G"
else
  echo "Info: SD file $SD_NAME already exists. Skipping processing."
fi

echo "Check SD file $SD_NAME info"
qemu-img info "$SD_NAME"

exec "$@"

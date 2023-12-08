# docker-qemu-rpi
# Docker Compose Setup for Multi-Service setup RaspberryPi OS in QEMU emulator inside docker

This repository contains the Docker Compose configuration for a multi-service application using several custom Docker images.

## Services

### 1. Updater Service

- **Image:** greenukr/updater:0.1.0
- **Purpose:** Build an updated Alpine image with a non-root user and chown the specified volume.
- **Command:** `chown -R ${USER_UID}:${GROUP_GID} /data`
- **Environment Variables:** Loaded from `.env` file.

### 2. Downloader Service

- **Image:** greenukr/downloader:0.5.0
- **Purpose:** Download data to the specified volume.
- **Environment Variables:** Loaded from `.env` and `.downloader.env` files.
- **Depends On:** updater (condition: service_completed_successfully)

### 3. Processor Service

- **Image:** greenukr/processor:0.5.0
- **Purpose:** Process data from the specified volume.
- **Environment Variables:** Loaded from `.env`, `.downloader.env`, and `.processor.env` files.
- **Depends On:** downloader (condition: service_completed_successfully)

### 4. Emulator Service

- **Image:** greenukr/emulator:0.5.0
- **Purpose:** Run an emulator with specified configurations.
- **Environment Variables:** Loaded from `.env` and `.processor.env` files.
- **Ports:** 2222:2222
- **Depends On:** processor (condition: service_completed_successfully)
- **Command:**
  ```bash
  -name rpi3bp -machine raspi3b -cpu cortex-a72 -m 1G -smp 4 -nographic
  -dtb ${DTB_FILE} -kernel ${KERNEL_FILE} -sd ${SD_NAME}
  -append "rw earlyprintk loglevel=8 console=ttyAMA0,115200 dwc_otg.lpm_enable=0 root=/dev/mmcblk0p2 rootdelay=1"
  -device usb-net,netdev=net0,mac=02:ca:fe:f0:0d:01 -netdev user,id=net0,hostfwd=tcp::2222-:22
  -monitor telnet:127.0.0.1:5555,server,nowait
  -monitor unix:qemu-monitor-socket,server,nowait

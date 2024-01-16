# docker-qemu-rpi/rpi3

## Emulate RaspberryPi OS in QEMU inside docker container
This repository contains the Docker Compose configuration for a multi-service build several custom Docker images and run RaspberryPi OS as a QEMU VM inside docker container.
You may access running container via SSH to localhost on port 2222.

### Default Credentials
Default Credentials: ***admin:admin***

**Important: I strongly advising you to change the default credentials after initial setup for security reasons. Using default credentials, especially in a public repository, can pose a security risk.**<br>
It's also possible to change Default Credentials `ADMIN_USER` and `ADMIN_PASSWORD` variables in [processor.env](./processor.env) file. But don't forget that Default Credentials will be showen in docker image.

Dockerfiles and entrypoint.sh located in directories named correspondingly. 
```
│   .downloader.env
│   .env
│   .processor.env
│   docker-compose.yaml
│   README.md
│
├───downloader
│       Dockerfile.downloader
│       entrypoint.downloader.sh
│
├───emulator
│       Dockerfile.emulator
│       entrypoint.emulator.sh
│
├───processor
│       Dockerfile.processor
│       entrypoint.processor.sh
│
└───updater
        Dockerfile.updater
```

### Getting started with building your images
Getting started is as simple as cloning this repository on your machine. You can do so with:
```bash
git clone https://github.com/GreenUkr/docker-qemu-rpi.git
```
After cloning the repository, you can move to the next step and start configuration. All the necessary files are located in the [rpi3](./rpi3) directory, so don't forget to change the directory:
```bash
cd rpi3
```

### Config
Upon execution, docker compose will look for environment variables in the directory where `docker-compose.yaml` is located. Docker compose uses the file `.env` itself and other files with extention `.env` to set environment variables for services.

The following environment variables are supported:
* `USER_UID` required (Default: `1000`)
* `GROUP_GID` required (Default: `1000`)
* `UG_NAME`  required (Default: `nonroot`)
    <br>User and Group IDs and Names to set nonroot ownership to mounted volume (You may use your own UID:GID to simplify external access to files in volume)
* `IMAGE_URL` required (Default: `https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2023-05-03/2023-05-03-raspios-bullseye-arm64-lite.img.xz`)
    <br>Link to download RaspiOS image 
* `SD_SIZE` required (Default: `4`)
    <br>Desired size of SD card in Gb
* `SD_NAME` required (Default: `sd.img`)
    <br>SD card file name
* `DTB_FILE` required (Default: `bcm2710-rpi-3-b-plus.dtb`)
* `KERNEL_FILE` required (Default: `kernel8.img`)
    <br>dtb and kernel file names should be get from the image 

The name of the image, dtb and kernel should be set accordingly to desired vm.

### How to build
Start the images build with command:
```bash
docker compose build
```
This creates all images to use with non root user.
Separate build is possible with:
```bash
docker compose build <service_name>
```
For debuging purpose Emulator Service image comtains some additional pkgs for testing. All except `qemu-system-aarch64` may be removed from Dockerfile. Of course, `qemu-system-aarch64` may be changed to `qemu-system-arm` if you want to emulate 32bit machine.

### How to run
Start the containers with command:
```bash
docker compose up
```
This run all containers to use with non root user.
Separate run is possible with:
```bash
docker compose up <service_name>
```
For debuging purpose all built containers left on host. Procedure creates docker volume and step-by-step (acording to dependance) runs containers. Only last `emulator` container emulates vm, all other may be removed when they stoped.
Build-in entrypoint and command of `emulator` container shows `qemu-system-aarch64` help.

### Volume
Volume `data-volume` created and mounted to `/data` dir in each container

### Services
#### 1. Updater Service
- **Image:** greenukr/updater
- **Purpose:** Build an updated Alpine image with a non-root user and chown the specified volume.
- **Command:** `chown -R ${USER_UID}:${GROUP_GID} /data`
- **Environment Variables:** Loaded from `.env` file.

#### 2. Downloader Service
- **Image:** greenukr/downloader
- **Purpose:** Download data to the specified volume.
- **Environment Variables:** Loaded from `.env` and `.downloader.env` files.
- **Depends On:** updater (condition: service_completed_successfully)

#### 3. Processor Service
- **Image:** greenukr/processor
- **Purpose:** Process data from the specified volume.
- **Environment Variables:** Loaded from `.env`, `.downloader.env`, and `.processor.env` files.
- **Depends On:** downloader (condition: service_completed_successfully)
- **Default Credentials:** admin:admin to access via SSH  

#### 4. Emulator Service
- **Image:** greenukr/emulator
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

### TODO
- [x] Create README.md
- [ ] Use sed to change config.txt in raspi image to remove BT and WiFi
- [ ] Get kernel and dtb from [raspberrypi/firmware](https://github.com/raspberrypi/firmware)
- [ ] Compile custom image from the [souce](https://github.com/RPi-Distro/pi-gen) with `USE_QEMU` flag 
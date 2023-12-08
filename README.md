# docker-qemu-rpi
## Docker Compose Setup RaspberryPi OS in QEMU inside docker container

This repository contains the Docker Compose configuration for a multi-service build several custom Docker images and run RaspberryPi OS as a QEMU VM inside docker container.
You may access running container via SSH to localhost on port 2222 with Default Credentials: ***admin:admin***  
```
│   .gitignore
│   README.md
│   rpi-docker.code-workspace
│
└───rpi3
    │   .downloader.env
    │   .env
    │   .processor.env
    │   docker-compose.yaml
    │   README.md
    │   TODO.txt
    │
    ├───downloader
    │       Dockerfile.downloader
    │       Dockerfile.downloader.bak
    │       entrypoint.downloader.sh
    │
    ├───emulator
    │       Dockerfile.emulator
    │       entrypoint.emulator.sh
    │
    ├───processor
    │       Dockerfile.processor
    │       Dockerfile.processor.bak
    │       entrypoint.processor.sh
    │       entrypoint.processor.sh.bak
    │
    └───updater
            Dockerfile.updater
```
### Requirements
Host with docker and docker compose installed (possible to run under Docker descktop in windows) to build and run containets. SSH client to get inside emulated rpi.

### Port 2222
The default port 2222 to access vm.

### Getting started with building your images
Getting started is as simple as cloning this repository on your machine. You can do so with:
```
git clone https://github.com/GreenUkr/docker-qemu-rpi.git
```
After cloning the repository, you can move to the next step and start configuration.
All needed files located in [rpi3](./rpi3) directory, so dont forget cd [there](./rpi3).
More detailed help in [rpi3/README.md](./rpi3/README.md)

### Regarding Qcow2 image building
Unfortunatelly all my attempts to start vm with image converted to qcow2 has been failed. VM failed to start after filesystem grow to get whole sd image size.  
# docker-qemu-rpi

## Emulate RaspberryPi OS in QEMU inside docker container
This repository contains the Docker Compose configuration for a multi-service build several custom Docker images and run RaspberryPi OS as a QEMU VM inside docker container.
You may access running container via SSH to localhost on port 2222.

### Requirements
Host with docker and docker compose installed (possible to run under Docker Desktop in windows) to build and run containts. SSH client to get inside emulated rpi.

### Default Credentials
Default Credentials: ***admin:admin***  

### Port 2222
The default port 2222 on localhost to access VM.

### Getting started with building your images
Getting started is as simple as cloning this repository on your machine. You can do so with:
```bash
git clone https://github.com/GreenUkr/docker-qemu-rpi.git
```
After cloning the repository, you can move to the next step and start configuration. All the necessary files are located in the [rpi3](./rpi3) directory, so don't forget to change the directory:
```bash
cd rpi3
```
For more detailed instructions, please refer to the [rpi3/README.md](./rpi3/README.md) file.

### Regarding Qcow2 image building
Unfortunately, all my attempts to start the VM with an image converted to qcow2 have failed. The VM fails to start after the filesystem grows to the full size of the SD image. If you have insights or solutions to this issue, please feel free to contribute or share your findings.

#!/bin/sh

set -e

SD_BASE_NAME="sd_base.img"
SD_RAW_NAME="sd.img"
SD_NAME="sd.qcow2"


# Main code
echo "Starting processor..."


exec "$@"

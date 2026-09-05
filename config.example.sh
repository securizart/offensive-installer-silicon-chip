#!/usr/bin/env bash
# Copy this file as config.sh and adjust the values to your machine.
# NEVER commit your personal config.sh if it contains machine-identifying
# details you'd rather not share.

# External disk identifier (use `diskutil list` to find it).
# Example: /dev/disk4
EXTERNAL_DISK=""

# Target distro: "kali" or "parrot"
TARGET_DISTRO=""

# Size of the root filesystem partition on the external disk (GB)
ROOT_PARTITION_SIZE_GB=60

# Hostname the installed system will have
HOSTNAME="offensive-m1"

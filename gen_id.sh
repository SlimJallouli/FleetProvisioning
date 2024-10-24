#!/bin/bash
 
# Get the hostname
HOSTNAME=$(hostname)
 
# Generate a DUID (using the MAC address)
DUID=$(cat /etc/machine-id)  # Alternatively, you can use MAC address: `ip link | awk '/ether/{print $2}'`
 
# Combine hostname and DUID to create a unique device name
DEVICE_NAME="${HOSTNAME}-${DUID}"
 
# Print or use the unique device name
echo "Unique Device Name: $DEVICE_NAME"
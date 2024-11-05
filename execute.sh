#!/bin/bash

# Define the YAML file
TEMPLATE_FILE="template.yaml"

# Function to display help
usage() {
    echo "Usage: $0 -ip REMOTE_IP_ADDRESS"
    exit 1
}

# Parse command line arguments
while getopts ":ip:" opt; do
    case ${opt} in
        ip )
            REMOTE_IP_ADDRESS=$OPTARG
            ;;
        \? )
            usage
            ;;
    esac
done

# Check that the IP address argument is provided
if [ -z "$REMOTE_IP_ADDRESS" ]; then
    usage
fi

# Copy files to the remote server
scp -r ./* root@$REMOTE_IP_ADDRESS:~
if [ $? -ne 0 ]; then
    echo "Error: Failed to copy files to $REMOTE_IP_ADDRESS"
    exit 1
fi

# Make the setup.sh script executable and run it on the remote server
ssh root@$REMOTE_IP_ADDRESS "chmod +x ~/setup.sh && ~/setup.sh"
if [ $? -ne 0 ]; then
    echo "Error: Failed to execute setup.sh on $REMOTE_IP_ADDRESS"
    exit 1
fi

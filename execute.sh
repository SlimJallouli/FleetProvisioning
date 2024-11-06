#!/bin/bash

#******************************************************************************
# * @file           : execute.sh
# * @brief          : 
# ******************************************************************************
# * @attention
# *
# * <h2><center>&copy; Copyright (c) 2022 STMicroelectronics.
# * All rights reserved.</center></h2>
# *
# * This software component is licensed by ST under BSD 3-Clause license,
# * the "License"; You may not use this file except in compliance with the
# * License. You may obtain a copy of the License at:
# *                        opensource.org/licenses/BSD-3-Clause
# ******************************************************************************

# Define the YAML file
TEMPLATE_FILE="template.yaml"

# Function to display help
usage() {
    echo "Usage: $0 -i REMOTE_IP_ADDRESS"
    exit 1
}

# Parse command line arguments
while getopts ":i:" opt; do
    case ${opt} in
        i )
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

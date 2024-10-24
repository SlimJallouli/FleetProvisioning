#!/bin/bash

# Source the configuration file
# LOAD_CONFIG_FILE="./load_config.sh"
# CONFIG_FILE_PATH="/opt/greengrass/v2/config/config.yaml"
CONFIG_YAML_FILE="/config.yaml"
source $LOAD_CONFIG_FILE

source gen_id.sh

# systemctl stop greengrass

# rm /opt/greengrass/v2/config/config.tlog*

sed -i "s/thingName: .*/thingName: \"${DEVICE_NAME}\"/g" $CONFIG_YAML_FILE
sed -i "s/awsRegion: .*/awsRegion: \"${REGION}\"/g" $CONFIG_YAML_FILE
sed -i "s/iotCredEndpoint: .*/iotCredEndpoint: \"${CRED_ENDPOINT}\"/g" $CONFIG_YAML_FILE
sed -i "s/iotDataEndpoint: .*/iotDataEndpoint: \"${DATA_ENDPOINT}\"/g" $CONFIG_YAML_FILE
sed -i "s/iotRoleAlias: .*/iotRoleAlias: \"${ROLE_ALIAS_NAME}\"/g" $CONFIG_YAML_FILE


    version: 2.13.0
    
# Echo Greengrass installer version
# java -jar ./GreengrassInstaller/lib/Greengrass.jar --version

# systemctl start greengrass

# echo "Greengrass configured and restarted."

script_name=$(basename "$0")
echo "$script_name script execution completed."
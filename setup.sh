#!/bin/bash

export ARG_GG_VERSION=2.13.0


USER_NME=$1

export GG_INSTALLER_PATH="/home/$USER_NME/GreengrassInstaller"
echo $GG_INSTALLER_PATH

gen_id()
{
  # Get the hostname
  HOSTNAME=$(hostname)
 
  # Generate a DUID (using the MAC address)
  DUID=$(cat /etc/machine-id)  # Alternatively, you can use MAC address: `ip link | awk '/ether/{print $2}'`
 
  # Combine hostname and DUID to create a unique device name
  DEVICE_NAME="${HOSTNAME}-${DUID}"  
}

gen_id

# Update the config file
# Update ThingName
sed -i 's|"ThingName": "[^"]*"|"ThingName": "'"$DEVICE_NAME"'"|' config.json
sed -i 's|"version": "[^"]*"|"version": "'"$ARG_GG_VERSION"'"|' config.json

# Make GG root directory
sudo mkdir -p /greengrass/v2
sudo chmod 755 /greengrass
 
# Copy claim certs to GG root directory
sudo cp -r ./claim-certs /greengrass/v2/claim-certs
 
# Download Amazon RootCA to GG root directory
sudo curl -o /greengrass/v2/AmazonRootCA1.pem https://www.amazontrust.com/repository/AmazonRootCA1.pem
 
# Install dependencies
sudo apt install -y default-jdk unzip curl
 
# Create user and group
sudo useradd --system --create-home ggc_user
sudo groupadd --system ggc_group
 
 
# Download and unzip greengrass installer
curl -s https://d2s8p88vqu9w66.cloudfront.net/releases/greengrass-$ARG_GG_VERSION.zip > greengrass-nucleus-latest.zip
unzip greengrass-nucleus-latest.zip -d $GG_INSTALLER_PATH && rm greengrass-nucleus-latest.zip
 
# Download fleet provisioning plugin
curl -s https://d2s8p88vqu9w66.cloudfront.net/releases/aws-greengrass-FleetProvisioningByClaim/fleetprovisioningbyclaim-latest.jar > $GG_INSTALLER_PATH/aws.greengrass.FleetProvisioningByClaim.jar

# Echo Greengrass installer version
java -jar $GG_INSTALLER_PATH/lib/Greengrass.jar --version

# Copy config file
sudo cp ./config.json $GG_INSTALLER_PATH/config.json
 
# Run installer
sudo -E java -Droot="/greengrass/v2" -Dlog.store=FILE \
  -jar $GG_INSTALLER_PATH/lib/Greengrass.jar \
  --trusted-plugin $GG_INSTALLER_PATH/aws.greengrass.FleetProvisioningByClaim.jar \
  --init-config $GG_INSTALLER_PATH/config.json \
  --component-default-user ggc_user:ggc_group \
  --setup-system-service true
 
# Delete GreengrassInstaller
 sudo rm -rf $GG_INSTALLER_PATH/

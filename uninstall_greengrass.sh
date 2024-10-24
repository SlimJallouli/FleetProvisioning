#!/bin/bash

USER_NME=$1

cd ~
# sudo systemctl stop greengrass.service
# sudo systemctl disable greengrass.service
# sudo rm /etc/systemd/system/greengrass.service
# sudo systemctl daemon-reload && sudo systemctl reset-failed
# sudo rm -rf /greengrass/v2

sudo rm -rf /home/$USER_NME/GreengrassInstaller/
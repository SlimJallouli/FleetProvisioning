#!/bin/bash

USER_NME=$USER

cd ~
systemctl stop greengrass.service
systemctl disable greengrass.service
rm /etc/systemd/system/greengrass.service
systemctl daemon-reload && systemctl reset-failed
rm -rf /greengrass/v2

rm -rf /home/$USER_NME/GreengrassInstaller/
#!/bin/bash
# Terraform passes this to AWS as the user_data for the instance, and it acts as a script that runs when the instance first boots

set -e

# This all just changes the admin password for splunk
sudo rm /opt/splunk/etc/passwd

echo "[user_info]" > ./user-seed.conf
echo "USERNAME = admin" >> ./user-seed.conf
echo "PASSWORD = ${splunk_admin_password}" >> ./user-seed.conf

sudo chown splunk:splunk ./user-seed.conf
sudo mv ./user-seed.conf /opt/splunk/etc/system/local/user-seed.conf

cd /opt/splunk/bin
sudo ./splunk restart

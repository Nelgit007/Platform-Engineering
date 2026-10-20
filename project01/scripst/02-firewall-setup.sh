#!/bin/bash
# 02-firewall-setup.sh — allows only SSH and HTTP through the firewall.
# The app-service and database stay unreachable from outside on purpose.

set -e

echo "[2/5] Setting up firewall rules..."

sudo apt-get install -y ufw > /dev/null

sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # nginx (public)
sudo ufw --force enable

echo "Firewall enabled. Current rules:"
sudo ufw status

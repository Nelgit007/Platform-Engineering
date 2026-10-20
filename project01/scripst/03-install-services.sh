#!/bin/bash
# 03-install-services.sh — installs nginx, python3, and postgresql.

set -e

echo "[3/5] Installing services..."

sudo apt-get update -y
sudo apt-get install -y nginx python3 postgresql

echo "Installation complete."

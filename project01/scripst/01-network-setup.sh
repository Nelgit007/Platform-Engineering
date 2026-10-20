#!/bin/bash
# 01-network-setup.sh — adds simple internal hostnames so services
# can refer to each other by name instead of hardcoded IPs.

set -e

echo "[1/5] Setting up network hostnames..."

if ! grep -q "app-service.local" /etc/hosts; then
    echo "127.0.0.1   app-service.local" | sudo tee -a /etc/hosts
    echo "127.0.0.1   db-service.local" | sudo tee -a /etc/hosts
    echo "Hostnames added."
else
    echo "Hostnames already exist, skipping."
fi

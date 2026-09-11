#!/bin/bash
set -euo pipefail

echo "Configuring firewall rules..."

ufw allow 22/tcp    comment 'SSH'
ufw allow 80/tcp    comment 'Nginx HTTP'
ufw allow 443/tcp   comment 'Nginx HTTPS'

ufw --force enable
ufw status verbose

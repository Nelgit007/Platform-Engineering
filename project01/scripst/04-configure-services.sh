#!/bin/bash
# 04-configure-services.sh — sets up app-service as a systemd service
# and points nginx at it as a reverse proxy.

set -e

echo "[4/5] Configuring services..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Copy the app to a standard location
sudo mkdir -p /opt/app-service
sudo cp "$PROJECT_ROOT/app/app.py" /opt/app-service/app.py

# Create a simple systemd service for it
sudo tee /etc/systemd/system/app-service.service > /dev/null <<EOF
[Unit]
Description=Simple App Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/app-service/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now app-service

# Point nginx at it
sudo cp "$PROJECT_ROOT/configs/nginx.conf.template" /etc/nginx/sites-available/app-proxy
sudo ln -sf /etc/nginx/sites-available/app-proxy /etc/nginx/sites-enabled/app-proxy
sudo rm -f /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl enable --now nginx
sudo systemctl reload nginx

sudo systemctl enable --now postgresql

echo "Services configured and running."

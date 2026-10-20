#!/bin/bash
# deploy.sh — runs the full setup, in order.
#
# Usage: sudo ./deploy.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$SCRIPT_DIR/scripts/01-network-setup.sh"
bash "$SCRIPT_DIR/scripts/02-firewall-setup.sh"
bash "$SCRIPT_DIR/scripts/03-install-services.sh"
bash "$SCRIPT_DIR/scripts/04-configure-services.sh"

echo
echo "Deployment complete. Checking status:"
bash "$SCRIPT_DIR/scripts/05-manage-services.sh" status

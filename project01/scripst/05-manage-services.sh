#!/bin/bash
# 05-manage-services.sh — start, stop, restart, or check status of services.
#
# Usage:
#   ./05-manage-services.sh status
#   ./05-manage-services.sh start|stop|restart <service>
#
# <service> is: nginx | app-service | postgresql

SERVICE=$2

case $1 in
  status)
    echo "nginx:       $(systemctl is-active nginx)"
    echo "app-service: $(systemctl is-active app-service)"
    echo "postgresql:  $(systemctl is-active postgresql)"
    ;;
  start|stop|restart)
    sudo systemctl "$1" "$SERVICE"
    echo "$SERVICE $1'd."
    ;;
  *)
    echo "Usage: $0 {status|start|stop|restart} [service]"
    exit 1
    ;;
esac

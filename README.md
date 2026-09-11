# Platform-Engineering
A hands-on guide to platform engineering

## Project 1
```
multi-service-linux-automation/
├── README.md
├── deployment_note
├── scripts/
│   ├── 01-network-setup.sh
│   ├── 02-firewall-setup.sh
│   ├── 03-install-services.sh
│   ├── 04-configure-services.sh
│   └── 05-manage-services.sh
├── configs/
│   └── nginx.conf.template
└── docs/
```

```
# Multi-Service Linux Environment Automation

Automates setup, networking, firewall configuration, and service management
for a multi-service Linux environment using shell scripts.

## Services Automated
- Nginx (web/reverse proxy)

## What This Automates
- Network configuration
- Firewall rules (least-privilege - only necessary ports exposed)
- Service installation
- Service configuration
- Self-healing health checks (auto-restart if a service goes down)

## Usage
\`\`\`bash
git clone <repo-url>
cd multi-service-linux-automation
chmod +x deploy.sh scripts/*.sh
sudo ./deploy.sh
\`\`\`

## Design Decisions
- Scripts are separated by concern (networking, firewall, install, config, management)
- Firewall rules follow least-privilege: only web-facing ports (80/443) are public;
- Service management script is idempotent and self-healing - safe to re-run,
  and will restart any service found not running.

## Validation
curl -I http://localhost  
```



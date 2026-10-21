<img width="1025" height="679" alt="3 tier Architecture" src="https://github.com/user-attachments/assets/38561b14-4c3c-47c3-9327-60f7879aa4a1" /># Three-Tier Architecture Deployment on AWS: Step-by-Step

This document walks through deploying the three-tier architecture (web, application, database) across two Availability Zones using the AWS Console. Each step lists what was created, the key settings, and how to verify it before moving on.

## Contents

1. [Architecture Design](#1-architecture-design)
2. [Create the VPC and Related Resources](#2-create-the-vpc-and-related-resources)
3. [Create the Security Groups](#3-create-the-security-groups)
4. [Create the Launch Templates](#4-create-the-launch-templates)
5. [Create the Auto Scaling Groups, Load Balancer and Target Group](#5-create-the-auto-scaling-groups-load-balancer-and-target-group)
6. [Create the Database](#6-create-the-database)
7. [Create the IAM Role and Update the Launch Template](#7-create-the-iam-role-and-update-the-launch-template)
8. [End-to-End Verification](#8-end-to-end-verification)
9. [Clean-Up](#9-clean-up)

---

## 1. Architecture Design
![Architecture diagram](./screenshots/)

**Design principles**
- Everything spans two Availability Zones.
- Only the load balancer is reachable from the internet.
- Each tier accepts traffic only from the tier directly in front of it.
- The database subnets have no route to the internet.

---

## 2. Create the VPC and Related Resources

### 2.1 Create the VPC

**VPC → Your VPCs → Create VPC**

| Setting | Value |
|---|---|
| Name | `three-tier-vpc` |
| IPv4 CIDR | `10.0.0.0/16` |
| Tenancy | Default |

Then enable DNS hostnames: **Actions → Edit VPC settings → Enable DNS hostnames**.

![VPC created](./screenshots/<img width="1920" height="1080" alt="vpc" src="https://github.com/user-attachments/assets/a80d0c25-06bc-4e0a-aa27-b9f0534fa61e" />
)

### 2.2 Create the subnets

**VPC → Subnets → Create subnet.** Create eight subnets, two per tier, one in each Availability Zone (replace the AZs with ones in your region).

| Name | AZ | CIDR | Tier |
|---|---|---|---|
| `public-a` | AZ-a | `10.0.0.0/24` | Public |
| `public-b` | AZ-b | `10.0.1.0/24` | Public |
| `web-a` | EU-a | `10.0.3.0/24` | Public (web-tier) |
| `web-b` | EU-b | `10.0.4.0/24` | Public (web-tier) |
| `app-a` | EU-a | `10.0.6.0/24` | Private (app-tier) |
| `app-b` | EU-b | `10.0.7.0/24` | Private (app-tier) |
| `db-a` | EU-a | `10.0.30.0/24` | Isolated (database) |
| `db-b` | EU-b | `10.0.31.0/24` | Isolated (database) |

For the two public subnets, enable auto-assign public IPv4: **Actions → Edit subnet settings**.

![Subnets created](./screenshots/<img width="1920" height="1080" alt="Screenshot (286)" src="https://github.com/user-attachments/assets/9bdd250c-2243-4d77-a26b-e62e3c66b4b1" />
)

### 2.3 Create and attach the Internet Gateway
An Internet Gateway (IGW) is a crucial component in your VPC that serves as a gateway between your public resources and the internet. it enables resources in public subnets to access the internet, and allows incoming traffic from the internet to reach your public resources.

**VPC → Internet gateways → Create internet gateway** (`three-tier-igw`), then **Actions → Attach to VPC**.

![Internet gateway attached](./screenshots/<img width="1920" height="1080" alt="Screenshot (288)" src="https://github.com/user-attachments/assets/8c711ac0-2919-4740-8160-26261b0fa7c7" />)

### 2.4 Create the NAT Gateways

**VPC → NAT gateways → Create NAT gateway.** Create one in each public subnet so each AZ has its own outbound path.

| Name | Subnet | Elastic IP |
|---|---|---|
| `nat-a` | `public-a` | Allocate new |
| `nat-b` | `public-b` | Allocate new |

![NAT gateways](./screenshots/02-nat-gateways.png)

### 2.5 Create the route tables

**VPC → Route tables → Create route table.**

| Route table | Routes | Associated subnets |
|---|---|---|
| `public-rt` | `0.0.0.0/0` → Internet Gateway | `public-a`, `public-b` |
| `private-rt-a` | `0.0.0.0/0` → `nat-a` | `web-a`, `app-a` |
| `private-rt-b` | `0.0.0.0/0` → `nat-b` | `web-b`, `app-b` |
| `db-rt` | Local route only, **no** `0.0.0.0/0` | `db-a`, `db-b` |

![Route tables](./screenshots/02-route-tables.png)

### Verify
- The VPC resource map (**VPC → Your VPCs → select VPC → Resource map**) shows all eight subnets and the correct route table for each.
- `db-rt` has no internet route.

![VPC resource map](./screenshots/02-vpc-resource-map.png)

---

## 3. Create the Security Groups

**VPC → Security groups → Create security group.** Create them in this order so each one can reference the previous one as its source.

| Security group | Inbound rule | Source |
|---|---|---|
| `alb-sg` | HTTP 80, HTTPS 443 | `0.0.0.0/0` |
| `web-sg` | HTTP 80 | `alb-sg` |
| `app-sg` | Custom TCP 3000 | `web-sg` |
| `db-sg` | PostgreSQL 5432 | `app-sg` |

Notes:
- Use the **security group ID as the source**, not a CIDR range. This is what enforces tier-to-tier access.
- No SSH (port 22) rule is added anywhere. Administrative access uses AWS Systems Manager Session Manager (configured in step 7).
- Keep the default outbound rules unless your policy requires tightening them.

![alb-sg rules](./screenshots/03-alb-sg.png)
![web-sg rules](./screenshots/03-web-sg.png)
![app-sg rules](./screenshots/03-app-sg.png)
![db-sg rules](./screenshots/03-db-sg.png)

### Verify
Each group's inbound rules list exactly one source, and only `alb-sg` allows `0.0.0.0/0`.

---

## 4. Create the Launch Templates

**EC2 → Launch Templates → Create launch template.** Create one for the web tier and one for the app tier.

### 4.1 Web tier (Nginx)

| Setting | Value |
|---|---|
| Name | `web-launch-template` |
| AMI | Amazon Linux 2023 |
| Instance type | `t3.micro` |
| Key pair | None (access via Session Manager) |
| Security group | `web-sg` |
| Storage | 8 GiB gp3, **encrypted** |

**Advanced details → User data:**

```bash
#!/bin/bash
dnf install -y nginx
systemctl enable nginx
systemctl start nginx
echo "OK" > /usr/share/nginx/html/health
```

![Web launch template](./screenshots/04-web-launch-template.png)

### 4.2 App tier (Node.js)

| Setting | Value |
|---|---|
| Name | `app-launch-template` |
| AMI | Amazon Linux 2023 |
| Instance type | `t3.micro` |
| Key pair | None |
| Security group | `app-sg` |
| Storage | 8 GiB gp3, **encrypted** |

**Advanced details → User data:**

```bash
#!/bin/bash
dnf install -y nodejs
mkdir -p /opt/app
```

![App launch template](./screenshots/04-app-launch-template.png)

> The IAM instance profile is added to both templates in step 7, once the role exists.

### Verify
Both templates appear under **EC2 → Launch Templates** with version 1.

---

## 5. Create the Auto Scaling Groups, Load Balancer and Target Group

### 5.1 Create the target group

**EC2 → Target Groups → Create target group**

| Setting | Value |
|---|---|
| Target type | Instances |
| Name | `web-tg` |
| Protocol / Port | HTTP / 80 |
| VPC | `three-tier-vpc` |
| Health check path | `/health` |
| Healthy / unhealthy threshold | 2 / 3 |

Do not register targets manually. The Auto Scaling Group registers them.

![Target group](./screenshots/05-target-group.png)

### 5.2 Create the Application Load Balancer

**EC2 → Load Balancers → Create → Application Load Balancer**

| Setting | Value |
|---|---|
| Name | `three-tier-alb` |
| Scheme | Internet-facing |
| VPC | `three-tier-vpc` |
| Subnets | `public-a`, `public-b` |
| Security group | `alb-sg` |
| Listener | HTTP:80 → forward to `web-tg` |

![Load balancer](./screenshots/05-alb.png)

> For production, add an HTTPS:443 listener with an ACM certificate and redirect HTTP to HTTPS.

### 5.3 Create the Auto Scaling Groups

**EC2 → Auto Scaling Groups → Create Auto Scaling group**

**Web tier**

| Setting | Value |
|---|---|
| Name | `web-asg` |
| Launch template | `web-launch-template` |
| Subnets | `web-a`, `web-b` |
| Load balancing | Attach to existing target group `web-tg` |
| Health checks | Turn on ELB health checks |
| Desired / min / max | 2 / 2 / 4 |
| Scaling policy | Target tracking, average CPU 60% |

**App tier**

| Setting | Value |
|---|---|
| Name | `app-asg` |
| Launch template | `app-launch-template` |
| Subnets | `app-a`, `app-b` |
| Load balancing | None (reached through the web tier) |
| Desired / min / max | 2 / 2 / 4 |
| Scaling policy | Target tracking, average CPU 60% |

![Web ASG](./screenshots/05-web-asg.png)
![App ASG](./screenshots/05-app-asg.png)

### Verify
- Instances launch, one per AZ.
- `web-tg` shows targets as **healthy**.
- Opening the load balancer's DNS name returns the Nginx response.

![Healthy targets](./screenshots/05-healthy-targets.png)

---

## 6. Create the Database

### 6.1 Create the DB subnet group

**RDS → Subnet groups → Create DB subnet group**

| Setting | Value |
|---|---|
| Name | `three-tier-db-subnet-group` |
| VPC | `three-tier-vpc` |
| Subnets | `db-a`, `db-b` |

![DB subnet group](./screenshots/06-db-subnet-group.png)

### 6.2 Create the RDS instance

**RDS → Databases → Create database**

| Setting | Value |
|---|---|
| Engine | PostgreSQL |
| Template | Production (or Dev/Test for cost) |
| Availability | **Multi-AZ DB instance** |
| Identifier | `three-tier-postgres` |
| Instance class | `db.t3.micro` |
| Storage | 20 GiB gp3, **encryption enabled** |
| Credentials | **Manage master credentials in AWS Secrets Manager** |
| Subnet group | `three-tier-db-subnet-group` |
| Public access | **No** |
| Security group | `db-sg` |
| Backup retention | 7 days |

Choosing "Manage master credentials in AWS Secrets Manager" means no password is typed, stored in code, or shared. RDS creates and rotates the secret for you.

![RDS configuration](./screenshots/06-rds-config.png)

Optionally, enforce TLS: create a parameter group with `rds.force_ssl = 1` and attach it to the instance.

### Verify
- Status is **Available** and Multi-AZ shows **Yes**.
- Public accessibility shows **No**.
- A secret for the instance exists in **Secrets Manager**. Note its ARN for the next step.

![RDS available](./screenshots/06-rds-available.png)

---

## 7. Create the IAM Role and Update the Launch Template

### 7.1 Create the IAM role

**IAM → Roles → Create role**

| Setting | Value |
|---|---|
| Trusted entity | AWS service → EC2 |
| Managed policy | `AmazonSSMManagedInstanceCore` |
| Name | `app-instance-role` |

Then add an inline policy that allows reading **only** the database secret:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:<region>:<account-id>:secret:<db-secret-name>"
    }
  ]
}
```

Replace the `Resource` with the exact ARN of the secret from step 6. Do not use `*`.

For the web tier, create a second role with only `AmazonSSMManagedInstanceCore`, since it does not need database credentials.

![IAM role](./screenshots/07-iam-role.png)
![Inline policy](./screenshots/07-iam-inline-policy.png)

### 7.2 Update the launch templates

**EC2 → Launch Templates → select template → Actions → Modify template (Create new version)**

- App template: **Advanced details → IAM instance profile → `app-instance-role`**.
- Web template: set the web role's instance profile the same way.
- Save as a new version, then **Actions → Set default version**.

![New launch template version](./screenshots/07-launch-template-v2.png)

### 7.3 Roll the change out to the Auto Scaling Groups

For each ASG: **Edit → Launch template version → Latest (or Default)**, then **Instance refresh → Start instance refresh** (minimum healthy 50%). New instances launch with the role attached and old ones are replaced gradually.

![Instance refresh](./screenshots/07-instance-refresh.png)

### Verify
- **EC2 → Instances → select an instance → Security tab** shows the IAM role.
- **Systems Manager → Fleet Manager** lists the instances as managed, so Session Manager works without opening port 22.

---

## 8. End-to-End Verification

| Check | How | Expected |
|---|---|---|
| Load balancer reachable | Open the ALB DNS name | Nginx response |
| Targets healthy | `web-tg` → Targets | All healthy, both AZs |
| Tier isolation | Try to reach `app-sg` instances from the internet | No access |
| Database isolation | Try to connect to RDS from outside the VPC | No access |
| Secrets access | From an app instance via Session Manager: `aws secretsmanager get-secret-value --secret-id <arn>` | Returns the secret |
| Secrets restriction | Same command against a different secret | Access denied |
| Self-healing | Terminate one web instance | ASG launches a replacement |
| Database failover | RDS → Actions → Reboot with failover | Standby takes over |

![Application running through the ALB](./screenshots/08-alb-response.png)

---

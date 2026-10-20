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


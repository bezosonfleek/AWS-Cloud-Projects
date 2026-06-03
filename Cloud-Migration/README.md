# Hybrid Cloud Migration Playbook: Proxmox to AWS 
  - Just a plan for now, execution to follow in a few days
---
This repository tracks the end-to-end migration strategy, architecture blueprints, and deployment configurations used to design, run, and transition a multi-tier production environment from an on-premises Proxmox VE cluster over to Amazon Web Services (AWS).

## 1. Migration Strategy Overview
To limit production downtime and eliminate configuration drift, this project adopts a phased lift-and-shift approach using **AWS Application Migration Service (MGN)**:
* **Phase 1 (Local Foundation):** Spin up the entire infrastructure from scratch on a Proxmox VE cluster to map internal dependencies and finalize application configurations.
* **Phase 2 (Continuous Replication):** Deploy AWS MGN replication agents inside the live Proxmox VMs to stream block-level data asynchronously into an AWS staging area.
* **Phase 3 (Dry-Run Testing):** Launch sandboxed test instances in AWS to validate security groups, internal networking, and database consistency.
* **Phase 4 (Live Cutover):** Stop on-prem traffic, flush the last modified data blocks to AWS, spin up live production EC2 instances, and update public DNS records.

---

## 2. On-Premises Architecture & Mapping Blueprint
To ensure seamless driver and network translations when the workloads land in AWS, the Proxmox environment relies exclusively on full QEMU virtual machines (no LXC containers), standard `VirtIO` paravirtualized drivers, and active guest agents.

### Target Instance Matrix

| Proxmox VM Name | Primary OS Stack | Local Network (Subnet Map) | Target AWS Component |
| :--- | :--- | :--- | :--- |
| `01-web-frontend` | Nginx / Apache | `10.0.1.10/24` (Public Subnet) | Amazon EC2 + Public ALB |
| `02-app-backend` | Node.js / Python API | `10.0.2.10/24` (Private App Subnet) | Amazon EC2 / AWS ECS |
| `03-database-srv` | PostgreSQL / MySQL | `10.0.3.10/24` (Isolated Data Subnet) | Amazon RDS for PostgreSQL |
| `04-shared-storage` | NFS Server / Samba | `10.0.2.20/24` (Private App Subnet) | Amazon Elastic File System (EFS) |
| `05-msg-queue` | Redis / RabbitMQ | `10.0.2.30/24` (Private App Subnet) | Amazon ElastiCache for Redis |
| `06-bg-worker` | Asynchronous Worker | `10.0.2.31/24` (Private App Subnet) | Amazon EC2 Auto Scaling Group |
| `07-directory-dns` | Active Directory / CoreDNS | `10.0.1.5/24` & `10.0.2.5/24` | AWS Directory Service |

---

## 3. Mandatory Provisioning Rules (Day 1)
To prevent driver compatibility issues or broken snapshots during the migration window, all Proxmox nodes must follow these mandatory system configurations:

1. **Enable the QEMU Guest Agent:** Toggle the `Qemu Guest Agent` checkbox under options, and install the daemon inside the guest OS:
   ```bash
   sudo apt update && sudo apt install qemu-guest-agent -y

2. Standardize on VirtIO Hardware: Configure storage controllers to use VirtIO SCSI and network cards to use VirtIO networking/storage drivers. 
   This ensures that guest kernels are already using drivers analogous to AWS Nitro NVMe and ENA standards.

3. Isolate OS and Storage Volumes: Provision operating systems on a primary drive, and split heavy write paths onto dedicated secondary virtual data disks.

## 4. Replication Setup
   Once the Proxmox architecture is stable, the replication pipeline is initialized by issuing temporary, restricted IAM credentials and running the AWS replication agent setup on each live local virtual machine:
   ```bash
   wget -O aws-replication-installer-init.py [https://aws-application-migration-service-us-east-1.s3.us-east-1.amazonaws.com/latest/linux/aws-replication-installer-init.py](https://aws-application-migration-service-us-east-1.s3.us-east-1.amazonaws.com/latest/linux/aws-replication-installer-init.py)

   sudo python3 aws-replication-installer-init.py --region us-east-1 --aws-access-key-id <IAM_KEY> --aws-secret-access-key <IAM_SECRET>

Note: Ensure outbound TCP ports 443 (for control communication) and 1500 (for block data streaming) are fully whitelisted on your local network firewall before executing the agent.
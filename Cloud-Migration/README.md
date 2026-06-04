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

## 3. Base Template & Mandatory Provisioning Rules

Before deploying any workloads, you must establish a golden, re-usable base template. If downloading a full 3GB+ desktop installation ISO is impossible due to network limits or file corruption, use the lightweight Ubuntu Cloud Image instead.

### Step 1: Download the Cloud Image File
Log into your Proxmox web UI, select your **local** storage pool, navigate to **ISO Images**, and click **Download from URL**. Paste the following verified path to grab the thin-provisioned Ubuntu 24.04 LTS footprint:

```bash
cd /var/lib/vz/template/iso && wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
```

### Step 2: Provision the Template VM Framework
Click Create VM in the top right of the GUI.

1. In General, set the VM ID to 1000 and name it golden-ubu-cloud.

2. In OS, choose Do not use any media.

3. In System, check Qemu Agent.

4. In Disks, set the Bus/Device interface to SCSI, provision a temporary placeholder disk, and finish the setup wizard.

5. Go directly to the VM's Hardware tab, select the placeholder Hard Disk, click Detach, and then click Remove to wipe it out entirely.

6. **Add the Cloud-Init Drive:** Still in the Hardware tab of VM 1000, click **Add** and select **Cloud-Init Drive**. Set the storage pool to `local-lvm` (or whichever storage pool holds your VM disks) and click **Add**. The device will appear in your hardware list as something like `ide0` or `sata0` with a type of `cloudinit`. This device is required for automated guest provisioning — it injects SSH keys, user credentials, and network configuration into the VM at first boot without manual console interaction.

### Step 2a: Configure Cloud-Init Credentials

With the Cloud-Init Drive now attached, navigate to the **Cloud-Init** tab of VM 1000 to set the login credentials that will be baked into the virtual configuration drive before first boot.

1. Double-click the **User** line, type your desired username (e.g., `ubuntu` or `admin`), and click **OK**.
2. Double-click the **Password** line, type your secure password, and click **OK**.
3. **Critical:** Click the **Regenerate Image** button at the top of the Cloud-Init tab. This compiles your username, password, and any configured SSH keys into the attached `cloudinit` drive. Without this step, the credentials are not written to the device and the VM will boot with no valid login.

### Step 3: Run the Block Storage Import

Because cloud-init .img files are raw virtual hard drives rather than bootable installation CD-ROMs, Proxmox must convert the file into a native block volume.

Open your Proxmox Node Shell (sakoracorp02) and run this single conversion utility:

```bash
qm importdisk 1000 /var/lib/vz/template/iso/noble-server-cloudimg-amd64.img local-lvm
```

### Step 4: Storage Optimization & Disk Expansion Behavior

Return to the Hardware tab of VM 1000. Select the newly populated Unused Disk 0 entry and click Edit.

Set the Bus/Device interface to SCSI.

Mechanical Hard Drive (HDD) Optimization: Because this cluster is powered by standard mechanical HDDs, keep IO Thread checked to prevent disk congestion from freezing the hypervisor UI. Leave Discard and SSD Emulation unchecked to allow the Linux kernel to utilize its mechanical drive arm elevator scheduling algorithms. Click Add.

Go to the Options tab, double-click Boot Order, check the box for scsi0, and drag it to the absolute top of the boot priority list.

Storage Warning Note: When verifying this imported disk inside the Proxmox inventory tabs, the virtual hardware configuration will read 3.5 GiB despite the download file measuring only 627 MiB. This is completely normal behavior. The 627 MiB file is a compressed, thin-provisioned archive for easy delivery; the 1st layer block translation extracts it instantly to its uncompressed, actual OS framework.

**Secondary Storage Allocation for `03-database-srv` and `04-shared-storage`:** Once these VMs are cloned and running, navigate to their respective **Hardware** tabs, click **Add**, and select **Hard Disk**. Set the Bus/Device to **SCSI**. As with the primary disk, leave **Discard** and **SSD Emulation** unchecked for HDD-backed storage pools to preserve native mechanical elevator scheduling. Allocate an appropriately sized secondary data drive to each node. This keeps all heavy transactional write paths (database data files, NFS exports) isolated from the OS disk, preventing I/O contention and simplifying snapshot management.

### Step 5: Finalize & Convert

Start the VM, open the **Console** tab, and boot into the instance. Click the **Shutdown** dropdown at the top right and select **Reset** (or **Stop** followed by **Start**) to trigger a clean boot cycle with the Cloud-Init drive active. Let the boot text scroll through — when the login prompt appears, enter the username and password you configured in Step 2a. Then execute the guest environment updates:

```bash
sudo apt update && sudo apt install qemu-guest-agent -y
```

Turn off the VM, right-click its name in the tree view, and select Convert to Template.

To prevent driver compatibility issues or broken snapshots during the migration window, all Proxmox nodes must follow these mandatory system configurations:

1. **Enable the QEMU Guest Agent:** Toggle the `Qemu Guest Agent` checkbox under options, and install the daemon inside the guest OS:
   ```bash
   sudo apt update && sudo apt install qemu-guest-agent -y
   ```

2. **Standardize on VirtIO Hardware:** Configure storage controllers to use VirtIO SCSI and network cards to use VirtIO networking/storage drivers.
   This ensures that guest kernels are already using drivers analogous to AWS Nitro NVMe and ENA standards.

3. **Isolate OS and Storage Volumes:** Provision operating systems on a primary drive, and split heavy write paths onto dedicated secondary virtual data disks.

## 4. Environment Deployment Order

When cloning workloads from your new golden template (1000), you must spin up instances in a strict dependency-based order to prevent downstream application network failures during initial boot sequences.

**07-directory-dns (Central Identity & Resolution) — First Priority:** Every service requires active DNS translation to authenticate and find resources. Clone this, apply your static layout (10.0.1.5/24), and map your internal records before proceeding.

**04-shared-storage (Shared Storage Pool) — Second Priority:** Hosts centralized configurations and shared asset exports via NFS. Set its DNS mapping to point directly back to the directory server.

**03-database-srv (Core Database Engine) — Third Priority:** The persistent transactional database must be alive and accepting private network queries before any backends boot up.

**05-msg-queue (Asynchronous Broker) — Fourth Priority:** Establishes the queuing environment (Redis/RabbitMQ) for application task handoffs.

**02-app-backend & 06-bg-worker (Compute Layer) — Fifth Priority:** Deployed together. They immediately try to connect to the database, file mount points, and message queues upon initialization.

**01-web-frontend (Public Gateway) — Final Priority:** The front-facing Nginx edge proxy. This is initialized last, only after its internal target backend application sockets are verified as up and running.

## 5. Replication Setup

Once the Proxmox architecture is stable, the replication pipeline is initialized by issuing temporary, restricted IAM credentials and running the AWS replication agent setup on each live local virtual machine:

```bash
wget -O aws-replication-installer-init.py https://aws-application-migration-service-us-east-1.s3.us-east-1.amazonaws.com/latest/linux/aws-replication-installer-init.py

sudo python3 aws-replication-installer-init.py --region us-east-1 --aws-access-key-id <IAM_KEY> --aws-secret-access-key <IAM_SECRET>
```

Note: Ensure outbound TCP ports 443 (for control communication) and 1500 (for block data streaming) are fully whitelisted on your local network firewall before executing the agent.

---

## 6. Cutover Validation & Fallback Procedures

Before live traffic redirection, execute continuous validation testing across the following three checkpoints. All three must pass cleanly before public DNS records are touched.

### AWS Target Group Routing Validation
Verify that each EC2 instance registered behind the Application Load Balancer is returning a healthy status in the AWS Target Group console. Confirm that routing rules correctly distribute requests to the `02-app-backend` compute layer and that no targets are in a draining or unhealthy state.

### Security Group Ingress Boundary Verification
Audit all Security Group inbound rules against the intended network topology. Confirm that:
* The public-facing ALB accepts inbound traffic on ports 80 and 443 only.
* The `02-app-backend` and `06-bg-worker` instances are reachable exclusively from within the private application subnet — not from the public internet.
* The `03-database-srv` RDS instance accepts connections only from the private app subnet CIDR, with no public accessibility enabled.
* The `05-msg-queue` ElastiCache endpoint is locked to internal VPC traffic only.

### Production Database Parity Checking
Prior to cutover, run a row-count and checksum comparison between the live Proxmox `03-database-srv` PostgreSQL instance and the target Amazon RDS instance to confirm transactional consistency. Verify that the final replicated snapshot contains no missing tables, orphaned foreign keys, or sequence drift on primary key columns.

### Phase 4 Rollback Procedure
If production sync failures, critical API connection timeouts, or failed health checks emerge at any point during the DNS cutover window, execute the following rollback sequence immediately:

1. **Halt DNS propagation** — if the TTL change has not yet fully propagated, revert the public DNS A record to point back to the on-premises Proxmox `01-web-frontend` public gateway IP (`10.0.1.10`) before any further changes are made.
2. **Re-enable on-premises traffic routing** — confirm the local Nginx gateway is still active and accepting connections. If it was shut down as part of the cutover, bring it back up immediately.
3. **Suspend the AWS MGN cutover job** — return to the AWS MGN console, select the affected source servers, and revert them to a pre-cutover replication state to prevent the staging instances from being finalized as production.
4. **Preserve the failed AWS instance state** — do not terminate EC2 instances or snapshots created during the failed cutover. Retain them for post-incident diagnostics to identify the root cause before reattempting.
5. **Document the failure point** — log the exact stage at which the failure occurred (Target Group health, Security Group rejection, DB parity mismatch, or DNS propagation error) to inform the remediation plan before scheduling a second cutover window.
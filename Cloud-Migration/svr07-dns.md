# Server Documentation: SVR07-DNS
## Active Directory Domain Controller & Core DNS Engine

| System Parameter | Configuration Value |
| :--- | :--- |
| **Hostname** | svr07-dns |
| **Domain Realm** | SAKORACORP02.SPACE |
| **NetBIOS Name** | SAKORACORP02 |
| **Operating System** | Ubuntu 24.04 LTS (Production Environment) |
| **Primary Role** | Samba4 Active Directory Domain Controller (AD DC) & BIND9 DLZ DNS |

---

## 1. Executive Summary & Purpose

The `svr07-dns` server acts as the central identity authority and primary directory infrastructure engine for the entire `sakoracorp02.space` network domain ecosystem. Operating under a simulated production framework, it combines the directory mechanics of a Windows-compatible Active Directory Domain Controller with the structural networking of BIND9. This integration ensures secure access, unified identity token authorization, localized domain record verification, and service path identification across all dependent node layers.

---

## 2. System Components & Architecture Matrix

The environment uses integrated server daemons to present a native Active Directory fabric. Below is the operational footprint of these tools:

| Service Daemon | Underlying Framework | Role Within Environment | Network Binding / State |
| :--- | :--- | :--- | :--- |
| `samba-ad-dc` | Samba 4.19.5 | Active Directory Controller, Kerberos KDC, SMB Core | Ports 88, 135, 389, 445, 464, 3268, 3269 |
| `named` | BIND 9.18.x | Dynamic Link Name Resolution via Samba DLZ Module | Port 53 (UDP/TCP) bound to 127.0.0.1 / Local IPs |
| `smbd / nmbd` | Samba File Layer | Standard SMB shares (Masked and replaced by AD DC) | Disabled & Masked |

---

## 3. DNS & Directory Layer Integration (BIND9 DLZ)

Instead of using Samba's basic internal DNS engine, this server leverages a production-grade **BIND9 Dynamically Loadable Zone (DLZ)** module. This enables BIND9 to access Samba's internal database memory blocks directly, resolving Active Directory service mapping indicators (SRV paths) in real time.

### 3.1. Local Link Architecture (`named.conf.local`)

To drop the static zone configurations and handle live zone queries dynamically, the configuration links directly to Samba's driver space:

```text
include "/var/lib/samba/bind-dns/named.conf";
```

### 3.2. Module Driver Selector (`/var/lib/samba/bind-dns/named.conf`)

The system is specifically tuned to ingest the BIND 9.18 implementation block, allowing it to load the underlying compiled architecture object:

```text
# For BIND 9.18.x
database "dlopen /usr/lib/x86_64-linux-gnu/samba/bind9/dlz_bind9_18.so";
```

**AppArmor Security Clearance Rules:**

Ubuntu enforces strict file access protection policies. To prevent access denial crashes, the system's primary security profile at `/etc/apparmor.d/usr.sbin.named` includes these access definitions:

```text
  /var/lib/samba/bind-dns/** rwk,
  /var/lib/samba/private/dns.keytab rk,
  /usr/lib/*/samba/**/*.so* rm,
```

---

## 4. Kerberos Security Ecosystem

Authentication validation within the network relies on a strict Kerberos V5 structural model. The machine's identity files have been migrated away from generic operating system templates and linked to Samba's live operational tokens:

```bash
sudo rm -f /etc/krb5.conf
sudo ln -s /var/lib/samba/private/krb5.conf /etc/krb5.conf
```

### 4.1. Domain Token Verification

Domain administrator identity tokens are validated via the `kinit` utility against the centralized Key Distribution Center (KDC). A normal validation routine follows this syntax:

```text
ubuntu@svr07-dns:~$ kinit administrator
Password for administrator@SAKORACORP02.SPACE:
# Response validation note: Password expires in 41 days.
```

---

## 5. Network Core Configuration (Netplan Alignment)

To prevent the local operating system from bypassing its internal Active Directory database structures on reboot, the loopback interface is defined as the priority name server within the network configuration files at `/etc/netplan/`:

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
      nameservers:
        addresses: [127.0.0.1]
        search: [sakoracorp02.space]
```

---

## 6. Production Validation Commands & Diagnostics Reference

Maintainers can check the status of the identity stack using these diagnostic tools:

- **Verify Active Shared Directories:** `smbclient -L localhost -U%` — Verifies active tracking for sysvol and netlogon.
- **Query Kerberos Global Directory Records:** `host -t SRV _kerberos._tcp.sakoracorp02.space. 127.0.0.1`
- **Check Internal Object Structure Tiers:** `samba-tool domain level show`
- **List Current Active Authentication Sessions:** `klist`

---

## 7. Maintenance & Hardening Guidelines

As this server sits in a production context, future administrative actions should focus on three target spaces:

**Adjust Account Expiration Rules:** Active Directory enforces a default 42-day lifespan. This constraint can be modified if needed using:

```bash
sudo samba-tool domain passwordsettings set --max-pwd-age=0
```

**Reverse Lookup Zone Generation:** Construct reverse map pointer scopes using the `samba-tool dns zonecreate` utility to allow client tracking.

**Automated Backup Infrastructure:** Configure an automated cron engine to capture point-in-time hot copies of the underlying database components:

```bash
sudo samba-tool domain backup online --targetdir=/var/backups/samba -U administrator
```
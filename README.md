# 🚀 KOBIR Multi‑VM Manager

A **feature‑rich Bash script** to manage QEMU/KVM virtual machines in a sleek **menu‑driven interface** with snapshots, backups, and multiple Linux distros supported ✨.

---

## 🖼 Banner

When you launch, you’re greeted by the **KOBIR ASCII Art**:

```
============================================================
_  _____  ____ ___ ____    ____  _   _    _    _   _ 
| |/ / _ \| __ )_ _|  _ \  / ___|| | | |  / \  | | | |
| ' / | | |  _ \| || |_) | \___ \| |_| | / _ \ | |_| |
| . \ |_| | |_) | ||  _ <   ___) |  _  |/ ___ \|  _  |
|_|\_\___/|____/___|_| \_\ |____/|_| |_/_/   \_\_| |_|
============================================================
              POWERED BY KOBIR 🚀
```

---

## ✨ Features

✅ **Interactive menu** (Create, Start, Stop, Info, Edit, Delete, Resize, Performance)  
✅ **12 OS presets** including Ubuntu, Debian, Fedora, CentOS, AlmaLinux, Rocky, Arch, Alpine, Kali, OpenSUSE, and Proxmox ISO  
✅ **Install location chooser** — store VMs anywhere (default: `~/vms`)  
✅ **Numbered VM selection** (choose by number or VM name)  
✅ **Snapshots** (create, list, restore, delete)  
✅ **Backups** (.tar.gz including config, disk, seed)  
✅ **Per‑VM config (.conf)** stores all VM details (OS, disk, CPUs, memory, ports…)  
✅ **Cloud‑init integration** (user/password auto‑injected)  
✅ **Passwordless SSH support** possible via public key injection  
✅ **Performance metrics** (show QEMU CPU/memory usage)  
✅ **GUI or headless mode** (choose when creating a VM)  
✅ Works with/without `lsblk` (falls back to `df`)  
✅ Portable & dependency validated  

---

## 🛠 Prerequisites

### Software
Install required tools:
```bash
sudo apt update
sudo apt install -y qemu-system qemu-utils cloud-image-utils wget
```

(Optional but recommended):
```bash
sudo apt install -y fzf
```
💡 If `fzf` is installed, menu selection gets fuzzy‑search capability.

### Hardware
- A Linux host with `KVM` support enabled  
- Sufficient disk/RAM for VMs  

---

## 🚀 Usage

### 1. Get the script
```bash
git clone https://github.com/MohammadKobirShah/vvmmss.git
cd vvmmss
chmod +x Kobir-Multi-VM.sh
```

### 2. Run it
```bash
./Kobir-Multi-VM.sh
```

### 3. Menu Options
```
Main Menu:
 1) Create VM
 2) Start VM
 3) Stop VM
 4) Show VM Info
 5) Edit VM Config
 6) Delete VM
 7) Resize VM Disk
 8) Show VM Performance
 9) Create Snapshot
10) List Snapshots
11) Restore Snapshot
12) Delete Snapshot
13) Backup VM
 0) Exit
```

---

## 🌐 Available Distros

- Ubuntu 22.04 LTS  
- Ubuntu 24.04 LTS  
- Debian 11  
- Debian 12  
- Fedora 40  
- CentOS Stream 9  
- AlmaLinux 9  
- Rocky Linux 9  
- Arch Linux (Rolling)  
- Alpine Linux 3.19  
- Kali Linux (Rolling)  
- OpenSUSE Leap 15.6  
- Proxmox VE 8.2 (ISO install mode)  

---

## 📸 Snapshots & Backups

- **Create Snapshot** → Saves VM state in qcow2  
- **List Snapshots** → Shows all saved states  
- **Restore Snapshot** → Rollback VM to a snapshot  
- **Delete Snapshot** → Remove a snapshot  
- **Backup** → Creates a tar.gz with VM disk(s), seed.iso, and config  

---

## 🧑‍💻 Example Flows

Create a new VM:
```text
[INPUT] Choice: 1
Available OS:
 1) Ubuntu 22.04
 2) Debian 12
 ...
[INPUT] VM name: mytest
[INPUT] Memory MB (default 2048): 1024
[SUCCESS] VM mytest created.
```

Start a VM (with numbered list):
```text
[INPUT] Choice: 2
Available VMs:
 1) mytest
 2) devserver
Choose VM (number or name): 1
[SUCCESS] Starting: mytest
```

Create snapshot:
```text
[INPUT] Choice: 9
Available VMs:
 1) mytest
Choose VM (number or name): mytest
Snapshot name: before-update
[SUCCESS] Snapshot before-update created
```

Backup a VM:
```text
[INPUT] Choice: 13
Available VMs:
 1) mytest
Choose VM (number or name): 1
[SUCCESS] Backup created: ~/vms/mytest-backup-2024-07-03.tar.gz
```

---

## 📂 File Layout

Each VM is stored like:
```
~/vms/
 ├─ mytest.conf         (saved configuration)
 ├─ disk.qcow2          (VM disk)
 ├─ seed.iso            (cloud-init ISO)
 └─ proxmox.iso (if using Proxmox ISO)
```

---

## 🔮 Future Roadmap

- VM cloning (templates)  
- Bridged networking labs (tap/bridge)  
- WebUI frontend (via noVNC + Flask REST API)  
- Graphical stats dashboard  

---

## 🏁 Credits

- Script by **KOBIR** ⚡  
- Inspired by classic **HopingBoyz** manager  
- Powered by **QEMU + KVM + cloud-init**  

---

✨ **Now your terminal is a datacenter.**  

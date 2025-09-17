#!/bin/bash
set -euo pipefail

# ============================
#   Enhanced Multi-VM Manager
# ============================

# === Colors ===
RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"
BLUE="\e[34m"; MAGENTA="\e[35m"; CYAN="\e[36m"; RESET="\e[0m"

# === Banner ===
display_header() {
    clear
    echo -e "${CYAN}============================================================${RESET}"
    echo -e "${MAGENTA}_  _____  ____ ___ ____    ____  _   _    _    _   _ ${RESET}"
    echo -e "${MAGENTA}| |/ / _ \\| __ )_ _|  _ \\  / ___|| | | |  / \\  | | | |${RESET}"
    echo -e "${MAGENTA}| ' / | | |  _ \\| || |_) | \\___ \\| |_| | / _ \\ | |_| |${RESET}"
    echo -e "${MAGENTA}| . \\ |_| | |_) | ||  _ <   ___) |  _  |/ ___ \\|  _  |${RESET}"
    echo -e "${MAGENTA}|_|\\_\\___/|____/___|_| \\_\\ |____/|_| |_/_/   \\_\\_| |_|${RESET}"
    echo -e "${CYAN}============================================================${RESET}"
    echo -e "${YELLOW}                POWERED BY KOBIR 🚀${RESET}\n"
}

# === Status helper ===
print_status() {
    local type=$1; local msg=$2
    case $type in
      INFO) echo -e "${BLUE}[INFO]${RESET} $msg";;
      WARN) echo -e "${YELLOW}[WARN]${RESET} $msg";;
      ERROR) echo -e "${RED}[ERROR]${RESET} $msg";;
      SUCCESS) echo -e "${GREEN}[SUCCESS]${RESET} $msg";;
      INPUT) echo -e "${CYAN}[INPUT]${RESET} $msg";;
      *) echo "[$type] $msg";;
    esac
}

# === Validate input ===
validate_input() {
    local type=$1 val=$2
    case $type in
        number) [[ $val =~ ^[0-9]+$ ]] || return 1 ;;
        size) [[ $val =~ ^[0-9]+[GgMm]$ ]] || return 1 ;;
        port) [[ $val =~ ^[0-9]+$ ]] && (( val > 22 && val <= 65535 )) || return 1 ;;
        name) [[ $val =~ ^[a-zA-Z0-9._-]+$ ]] || return 1 ;;
        username) [[ $val =~ ^[a-z_][a-z0-9_-]*$ ]] || return 1 ;;
    esac
    return 0
}

# === Dependencies ===
check_dependencies() {
    local deps=("qemu-system-x86_64" "wget" "cloud-localds" "qemu-img" "ss")
    local missing=()
    for d in "${deps[@]}"; do
        ! command -v "$d" &>/dev/null && missing+=("$d")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        print_status ERROR "Missing deps: ${missing[*]}"
        print_status INFO "Install with: sudo apt install qemu-system cloud-image-utils wget"
        exit 1
    fi
}

# === Paths ===
VM_DIR="${VM_DIR:-$HOME/vms}"
mkdir -p "$VM_DIR"

# === OS OPTIONS (11 distros + Proxmox) ===
declare -A OS_OPTIONS=(
 ["Ubuntu 22.04"]="ubuntu|jammy|https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img|ubuntu22|ubuntu|ubuntu"
 ["Ubuntu 24.04"]="ubuntu|noble|https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img|ubuntu24|ubuntu|ubuntu"
 ["Debian 11"]="debian|bullseye|https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2|debian11|debian|debian"
 ["Debian 12"]="debian|bookworm|https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2|debian12|debian|debian"
 ["Fedora 40"]="fedora|40|https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-40-1.14.x86_64.qcow2|fedora40|fedora|fedora"
 ["CentOS Stream 9"]="centos|stream9|https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2|centos9|centos|centos"
 ["AlmaLinux 9"]="almalinux|9|https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2|alma9|alma|alma"
 ["Rocky Linux 9"]="rockylinux|9|https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud.latest.x86_64.qcow2|rocky9|rocky|rocky"
 ["Arch Linux"]="arch|rolling|https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2|arch|arch|arch"
 ["Alpine Linux 3.19"]="alpine|3.19|https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/cloud/x86_64/alpine-cloud-3.19.1-x86_64.qcow2|alpine|alpine|alpine"
 ["Kali Linux"]="kali|rolling|https://cloud-images.kali.org/kali-latest/kalilinux.cloud.latest.qcow2|kali|kali|kali"
 ["OpenSUSE Leap 15.6"]="opensuse|15.6|https://download.opensuse.org/repositories/Cloud:/Images:/Leap_15.6/images/openSUSE-Leap-15.6-OpenStack.x86_64.qcow2|opensuse|suse|suse"
 ["Proxmox VE 8.2"]="proxmox|iso|https://enterprise.proxmox.com/iso/proxmox-ve_8.2-iso.iso|proxmox|root|root"
)

# === Helper functions ===
get_vm_list(){ find "$VM_DIR" -name "*.conf" -exec basename {} .conf \; 2>/dev/null | sort; }

load_vm_config(){
  local vm=$1; local cfg="$VM_DIR/$vm.conf"
  [[ -f $cfg ]] && source "$cfg" || { print_status ERROR "Config for $vm not found"; return 1; }
}

save_vm_config(){
  local cf="$VM_DIR/$VM_NAME.conf"
  cat > "$cf" <<EOF
VM_NAME="$VM_NAME"
OS_TYPE="$OS_TYPE"
CODENAME="$CODENAME"
IMG_URL="$IMG_URL"
HOSTNAME="$HOSTNAME"
USERNAME="$USERNAME"
PASSWORD="$PASSWORD"
DISK_SIZE="$DISK_SIZE"
MEMORY="$MEMORY"
CPUS="$CPUS"
SSH_PORT="$SSH_PORT"
IMG_FILE="$IMG_FILE"
SEED_FILE="$SEED_FILE"
CREATED="$(date)"
EOF
  print_status SUCCESS "Saved config: $cf"
}

choose_location(){
  print_status INFO "Available partitions:";
  lsblk -o NAME,MOUNTPOINT,SIZE | grep -E '/'; echo
  read -p "$(print_status INPUT 'Enter install path (default: ~/vms): ')" PATHSEL
  [[ -z $PATHSEL ]] && VM_DIR="$HOME/vms" || VM_DIR="$PATHSEL"
  mkdir -p "$VM_DIR"; print_status SUCCESS "Using VM dir: $VM_DIR"
}

# === VM Creation ===
create_new_vm(){
  choose_location
  print_status INFO "Select OS:"
  local i=1; local -a keys
  for os in "${!OS_OPTIONS[@]}"; do echo "  $i) $os"; keys[$i]="$os"; ((i++)); done
  read -p "$(print_status INPUT 'Choice: ')" pick
  local sel="${keys[$pick]}"; IFS="|" read -r OS_TYPE CODENAME IMG_URL DEFAULT_HOSTNAME DEFAULT_USER DEFAULT_PASS <<<"${OS_OPTIONS[$sel]}"
  [[ -z $sel ]] && { print_status ERROR "Invalid"; return; }

  read -p "$(print_status INPUT "VM name (default: $DEFAULT_HOSTNAME): ")" VM_NAME; VM_NAME=${VM_NAME:-$DEFAULT_HOSTNAME}
  read -p "$(print_status INPUT "Hostname (default: $VM_NAME): ")" HOSTNAME; HOSTNAME=${HOSTNAME:-$VM_NAME}
  read -p "$(print_status INPUT "Username (default: $DEFAULT_USER): ")" USERNAME; USERNAME=${USERNAME:-$DEFAULT_USER}
  read -s -p "$(print_status INPUT "Password (default: $DEFAULT_PASS): ")" PASSWORD; echo; PASSWORD=${PASSWORD:-$DEFAULT_PASS}
  read -p "$(print_status INPUT 'Disk size (default 20G): ')" DISK_SIZE; DISK_SIZE=${DISK_SIZE:-20G}
  read -p "$(print_status INPUT 'Memory MB (default 2048): ')" MEMORY; MEMORY=${MEMORY:-2048}
  read -p "$(print_status INPUT 'CPUs (default 2): ')" CPUS; CPUS=${CPUS:-2}
  read -p "$(print_status INPUT 'SSH Port (default 2222): ')" SSH_PORT; SSH_PORT=${SSH_PORT:-2222}

  local vm_path="$VM_DIR/$VM_NAME"; mkdir -p "$vm_path"
  IMG_FILE="$vm_path/disk.qcow2"; SEED_FILE="$vm_path/seed.iso"

  if [[ $OS_TYPE == "proxmox" ]]; then
    print_status INFO "Downloading Proxmox ISO..."
    wget -q "$IMG_URL" -O "$vm_path/proxmox.iso"
    qemu-img create -f qcow2 "$IMG_FILE" "$DISK_SIZE"
  else
    print_status INFO "Downloading image..."
    wget -q "$IMG_URL" -O "$vm_path/base.img"
    qemu-img convert -O qcow2 "$vm_path/base.img" "$IMG_FILE"
    qemu-img resize "$IMG_FILE" "$DISK_SIZE"

    # Cloud-init
    cat > user-data <<EOF
#cloud-config
hostname: $HOSTNAME
ssh_pwauth: true
users:
  - name: $USERNAME
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    password: $(openssl passwd -6 "$PASSWORD" | tr -d '\n')
chpasswd:
  list: |
    root:$PASSWORD
    $USERNAME:$PASSWORD
  expire: false
EOF
    echo "instance-id: iid-$VM_NAME" > meta-data
    echo "local-hostname: $HOSTNAME" >> meta-data
    cloud-localds "$SEED_FILE" user-data meta-data
  fi
  save_vm_config
}

# === VM Control ===
start_vm(){ load_vm_config "$1" || return; print_status INFO "Starting $VM_NAME"; 
  if [[ $OS_TYPE == "proxmox" ]]; then
    qemu-system-x86_64 -enable-kvm -m "$MEMORY" -smp "$CPUS" -cpu host \
    -drive file="$IMG_FILE",format=qcow2 \
    -cdrom "$VM_DIR/$VM_NAME/proxmox.iso" -boot d \
    -netdev user,id=n0,hostfwd=tcp::$SSH_PORT-:22 -device virtio-net-pci,netdev=n0
  else
    qemu-system-x86_64 -enable-kvm -m "$MEMORY" -smp "$CPUS" -cpu host \
    -drive file="$IMG_FILE",format=qcow2,if=virtio \
    -drive file="$SEED_FILE",format=raw,if=virtio \
    -netdev user,id=n0,hostfwd=tcp::$SSH_PORT-:22 -device virtio-net-pci,netdev=n0 \
    -nographic -serial mon:stdio
  fi
}

stop_vm(){ load_vm_config "$1" || return; pkill -f "qemu-system-x86_64.*$IMG_FILE" && print_status SUCCESS "Stopped $VM_NAME"; }
delete_vm(){ load_vm_config "$1" || return; rm -rf "$VM_DIR/$VM_NAME.*" "$VM_DIR/$VM_NAME"; print_status SUCCESS "Deleted $VM_NAME"; }
show_vm_info(){ load_vm_config "$1" && cat "$VM_DIR/$1.conf"; }
resize_vm_disk(){ load_vm_config "$1" || return; read -p "New size: " sz; qemu-img resize "$IMG_FILE" "$sz"; }
show_vm_performance(){ load_vm_config "$1" || return; pid=$(pgrep -f "qemu-system-x86_64.*$IMG_FILE") && top -p $pid || echo "Not running"; }

# === Menu ===
main_menu(){
while true; do
 display_header
 vms=($(get_vm_list)); vc=${#vms[@]}
 [ $vc -gt 0 ] && { print_status INFO "VMs: ${vms[*]}"; }
 echo "1) Create VM"; [ $vc -gt 0 ] && echo "2) Start VM" && echo "3) Stop VM" && echo "4) Show VM info" && echo "5) Delete VM" && echo "6) Resize VM disk" && echo "7) Show VM performance"
 echo "0) Exit"
 read -p "$(print_status INPUT 'Choice: ')" c
 case $c in
   1) create_new_vm;;
   2) read -p "VM name: " n; start_vm "$n";;
   3) read -p "VM name: " n; stop_vm "$n";;
   4) read -p "VM name: " n; show_vm_info "$n"; read;;
   5) read -p "VM name: " n; delete_vm "$n";;
   6) read -p "VM name: " n; resize_vm_disk "$n";;
   7) read -p "VM name: " n; show_vm_performance "$n"; read;;
   0) exit 0;;
 esac
done
}

# === START ===
check_dependencies
main_menu

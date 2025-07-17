#!/bin/bash
set -euo pipefail

# ========== 配置参数 ==========
UBUNTU_IMAGE_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-arm64.img"
UBUNTU_IMAGE="ubuntu-server.img"
DISK_IMAGE="ubuntu-disk.qcow2"
DISK_SIZE="20G"
MEMORY="4096"
CPUS="4"
SSH_PORT="2222"
BIOS_PATH="/opt/homebrew/Cellar/qemu/10.0.2_2/share/qemu/edk2-aarch64-code.fd"
SEED_ISO="seed.iso"

# ========== 检查并下载 Ubuntu 镜像 ==========
if [ ! -f "$UBUNTU_IMAGE" ]; then
  echo "🚀 下载 Ubuntu Cloud Image..."
  curl -L -o "$UBUNTU_IMAGE" "$UBUNTU_IMAGE_URL"
else
  echo "✅ 已存在 Ubuntu 镜像: $UBUNTU_IMAGE"
fi

# ========== 创建虚拟磁盘 ==========
if [ ! -f "$DISK_IMAGE" ]; then
  echo "💽 创建虚拟磁盘: $DISK_IMAGE ($DISK_SIZE)..."
  qemu-img create -f qcow2 "$DISK_IMAGE" "$DISK_SIZE"
else
  echo "✅ 已存在虚拟磁盘: $DISK_IMAGE"
fi

# ========== 检查 seed.iso ==========
if [ ! -f "$SEED_ISO" ]; then
  echo "❌ 缺少 cloud-init ISO 文件 seed.iso"
  echo "请先生成 seed.iso，例如："
  echo "  cloud-localds seed.iso user-data meta-data"
  exit 1
fi

# ========== 启动虚拟机 ==========
echo "🖥️ 启动 Ubuntu 虚拟机..."
qemu-system-aarch64 \
  -machine virt \
  -cpu cortex-a72 \
  -smp "$CPUS" \
  -m "$MEMORY" \
  -nographic \
  -bios "$BIOS_PATH" \
  -drive if=virtio,file="$DISK_IMAGE" \
  -drive if=virtio,file="$UBUNTU_IMAGE",format=qcow2 \
  -drive if=virtio,format=raw,file="$SEED_ISO" \
  -netdev user,id=net0,hostfwd=tcp::"$SSH_PORT"-:22 \
  -device virtio-net-device,netdev=net0


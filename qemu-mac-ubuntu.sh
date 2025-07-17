#!/bin/bash
set -euo pipefail

# ========== 配置参数 ==========
UBUNTU_IMAGE_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-arm64.img"
IMAGE_NAME="ubuntu-server.img"
DISK_NAME="ubuntu-disk.qcow2"
DISK_SIZE="20G"
MEMORY="4096"
CPUS="4"
SSH_PORT="2222"
BIOS_PATH="/opt/homebrew/share/qemu/edk2-aarch64-code.fd"  # QEMU 安装后存在

# ========== 下载 Ubuntu 镜像 ==========
if [ ! -f "$IMAGE_NAME" ]; then
  echo "🚀 下载 Ubuntu Cloud Image..."
  curl -L -o "$IMAGE_NAME" "$UBUNTU_IMAGE_URL"
else
  echo "✅ 镜像已存在: $IMAGE_NAME"
fi

# ========== 创建虚拟磁盘 ==========
if [ ! -f "$DISK_NAME" ]; then
  echo "💽 创建虚拟磁盘：$DISK_NAME ($DISK_SIZE)..."
  qemu-img create -f qcow2 "$DISK_NAME" "$DISK_SIZE"
else
  echo "✅ 虚拟磁盘已存在: $DISK_NAME"
fi

# ========== 启动虚拟机 ==========
echo "🖥️ 启动 Ubuntu 虚拟机（端口映射: localhost:$SSH_PORT → VM:22）..."
qemu-system-aarch64 \
  -machine virt \
  -cpu cortex-a72 \
  -smp "$CPUS" \
  -m "$MEMORY" \
  -nographic \
  -bios "$BIOS_PATH" \
  -drive if=virtio,file="$DISK_NAME" \
  -drive if=virtio,file="$IMAGE_NAME",format=raw \
  -netdev user,id=net0,hostfwd=tcp::"$SSH_PORT"-:22 \
  -device virtio-net-device,netdev=net0


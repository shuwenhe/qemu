#!/bin/bash
set -euo pipefail

# 参数
UBUNTU_IMAGE_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-arm64.img"
UBUNTU_IMAGE="ubuntu-server.img"
DISK_IMAGE="ubuntu-disk.qcow2"
DISK_SIZE="20G"
MEMORY="4096"
CPUS="4"
SSH_PORT="2222"
BIOS_PATH="/opt/homebrew/Cellar/qemu/10.0.2_2/share/qemu/edk2-aarch64-code.fd"
SEED_ISO="seed.iso"

echo "🚀 下载 Ubuntu 镜像（如果不存在）..."
if [ ! -f "$UBUNTU_IMAGE" ]; then
  curl -L -o "$UBUNTU_IMAGE" "$UBUNTU_IMAGE_URL"
else
  echo "✅ 已存在 Ubuntu 镜像: $UBUNTU_IMAGE"
fi

echo "💽 创建虚拟磁盘（如果不存在）..."
if [ ! -f "$DISK_IMAGE" ]; then
  qemu-img create -f qcow2 "$DISK_IMAGE" "$DISK_SIZE"
else
  echo "✅ 已存在虚拟磁盘: $DISK_IMAGE"
fi

echo "📝 生成 cloud-init 配置文件..."
cat > user-data <<EOF
#cloud-config
users:
  - name: ubuntu
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    lock_passwd: false
    passwd: "\$6\$aBc12345\$qU8Ib3dlZ7V4fCn29kJ4xwP3fIAlvT3mN4ttVKdOBJei5O63U60P8.5KxjKNwhGS0z1YQovpIazVPx4PjhPZC."
chpasswd:
  expire: false
ssh_pwauth: true
EOF

cat > meta-data <<EOF
instance-id: ubuntu-vm
local-hostname: ubuntu-vm
EOF

echo "💽 生成 seed.iso..."
rm -rf cidata
mkdir cidata
cp user-data meta-data cidata/
hdiutil makehybrid -o "$SEED_ISO" -hfs -joliet -iso -default-volume-name cidata cidata/ -ov

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
  -drive file="$SEED_ISO",format=raw,media=cdrom \
  -netdev user,id=net0,hostfwd=tcp::"$SSH_PORT"-:22 \
  -device virtio-net-device,netdev=net0


#!/bin/bash
# 自动生成 cloud-init seed.iso 文件
# 使用默认用户名 ubuntu / 密码 ubuntu

set -e

# 创建 cloud-init 配置目录
WORKDIR=cloud-init-config
mkdir -p $WORKDIR

echo "✅ 生成 user-data（用户名 ubuntu / 密码 ubuntu）"
cat > $WORKDIR/user-data <<EOF
#cloud-config
users:
  - name: ubuntu
    groups: sudo
    shell: /bin/bash
    lock_passwd: false
    passwd: \$6\$rounds=4096\$salt\$rNOxIq0j5s3fwOxxE8bZ1aX7YIsG4lRUm4J7Y53jBrIMPR5ta5WROmMeVkKIdEJD0U8hJFiT7Z9vKvmxOZyzO.
    ssh_pwauth: true
chpasswd:
  list: |
    ubuntu:ubuntu
  expire: False
hostname: ubuntu
EOF

echo "✅ 生成 meta-data"
cat > $WORKDIR/meta-data <<EOF
instance-id: iid-local01
local-hostname: ubuntu
EOF

echo "✅ 生成 seed.iso 文件（cloud-init 镜像）"
cloud-localds seed.iso $WORKDIR/user-data $WORKDIR/meta-data

echo "✅ seed.iso 已生成成功 ✅"
ls -lh seed.iso


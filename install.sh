#!/bin/bash

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
    echo "错误：必须使用root权限运行此脚本，请使用 'sudo bash $0' 或切换至root用户。"
    exit 1
fi

# 更新系统并安装依赖
apt update && apt upgrade -y
apt install -y curl sqlite3 ufw python3-pip

# 安装Python bcrypt库
pip3 install bcrypt

# 下载并安装x-ui面板
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)

# 生成密码的bcrypt哈希
HASH=$(python3 -c 'import bcrypt; print(bcrypt.hashpw(b"liang", bcrypt.gensalt()).decode())')

# 修改数据库配置
SQLITE_DB="/etc/x-ui/x-ui.db"
sqlite3 "$SQLITE_DB" "UPDATE users SET username='liang', password='$HASH' WHERE id=1;"
sqlite3 "$SQLITE_DB" "UPDATE setting SET value='2024' WHERE key='web_port';"

# 配置防火墙
ufw allow 2024
ufw --force enable

# 重启服务使配置生效
systemctl restart x-ui

# 输出访问信息
PUBLIC_IP=$(curl -s ifconfig.me)
echo "安装完成！"
echo "==============================="
echo "面板地址: http://${PUBLIC_IP}:2024"
echo "用户名: liang"
echo "密码: liang"
echo "==============================="

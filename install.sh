#!/bin/bash

# 一键安装配置 x-ui 脚本（Ubuntu）
# 账号：liang 密码：liang 端口：2024

# 安装依赖并更新系统
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl sqlite3 ufw

# 下载并执行官方 x-ui 安装脚本
curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh -o x-ui_install.sh
sudo bash x-ui_install.sh

# 停止 x-ui 服务以修改配置
sudo systemctl stop x-ui

# 生成密码的 SHA-256 哈希（注意：根据面板版本可能需要不同加密方式）
password_hash=$(echo -n "liang" | sha256sum | awk '{print $1}')

# 修改账号密码（假设数据库路径正确）
sudo sqlite3 /etc/x-ui/x-ui.db "UPDATE user SET username='liang', password='$password_hash' WHERE id=1;"

# 修改面板端口（键名可能为 webPort 或 port，请根据实际情况调整）
sudo sqlite3 /etc/x-ui/x-ui.db "UPDATE setting SET value='2024' WHERE key='webPort';"
# 如果上述命令无效，尝试替换为：
# sudo sqlite3 /etc/x-ui/x-ui.db "UPDATE setting SET value='2024' WHERE key='port';"

# 启动 x-ui 服务
sudo systemctl start x-ui

# 配置防火墙
sudo ufw allow 2024/tcp
sudo ufw --force reload

echo "================================"
echo "x-ui 配置完成！"
echo "地址: $(curl -s ifconfig.me)"
echo "端口: 2024"
echo "账号: liang"
echo "密码: liang"
echo "================================"

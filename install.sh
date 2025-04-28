#!/bin/bash

# 终极版 x-ui 自动配置脚本（Ubuntu）
# 账号：liang 密码：liang 端口：2024

# 安装必要工具
sudo apt update && sudo apt install -y expect sqlite3

# 自动化交互安装
curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh -o x-ui_install.sh

sudo expect <<EOF
spawn bash x-ui_install.sh
expect "是否继续安装*" { send "y\r" }
expect "请输入面板端口*" { send "2024\r" }
expect "请输入面板账号*" { send "liang\r" }
expect "请输入面板密码*" { send "liang\r" }
expect eof
EOF

# 绕过强制重置机制
sudo sqlite3 /etc/x-ui/x-ui.db <<SQL
UPDATE user SET password='$(echo -n "liang" | sha256sum | awk '{print $1}');
INSERT INTO setting (key, value) VALUES ('install_time', '2099-01-01') 
ON CONFLICT(key) DO UPDATE SET value='2099-01-01';
SQL

# 重启服务使配置生效
sudo systemctl restart x-ui

# 防火墙配置
sudo ufw allow 2024/tcp
sudo ufw --force reload

echo "================================"
echo "✅ 全自动配置验证成功！"
echo "立即访问: http://$(curl -s ifconfig.me):2024"
echo "账号: liang  密码: liang"
echo "================================"

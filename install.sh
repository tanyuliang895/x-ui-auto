#!/bin/bash

# 一键安装 x-ui + 自动设置账号密码端口（无证书版，绕过安全提示）

USERNAME="liang"
PASSWORD="liang"
PORT="2024"

green(){ echo -e "\033[32m$1\033[0m"; }
red(){ echo -e "\033[31m$1\033[0m"; }

[[ $EUID -ne 0 ]] && red "请用root用户运行脚本！" && exit 1

# 安装依赖
if command -v apt &> /dev/null; then
    apt update -y
    apt install -y curl wget sudo socat openssl bash-completion sqlite3
elif command -v yum &> /dev/null; then
    yum update -y
    yum install -y curl wget sudo socat openssl bash-completion sqlite
else
    red "不支持的Linux系统"
    exit 1
fi

# 安装x-ui
green "开始安装 x-ui..."
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)

# 停止x-ui服务
green "停止x-ui服务以便修改数据库..."
systemctl stop x-ui

# 修改数据库文件
DB_FILE="/etc/x-ui/x-ui.db"
if [ -f "$DB_FILE" ]; then
    green "正在修改数据库，设置账号密码端口..."
    sqlite3 $DB_FILE "UPDATE setting SET username='$USERNAME', password='$PASSWORD', port=$PORT;"
else
    red "未找到数据库文件，修改失败！"
    exit 1
fi

# 重启x-ui
green "重启x-ui服务..."
systemctl restart x-ui
systemctl enable x-ui

# 配置防火墙
green "配置防火墙放行端口..."
if command -v ufw &> /dev/null; then
    ufw allow "${PORT}/tcp"
    ufw reload
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port="${PORT}/tcp"
    firewall-cmd --reload
else
    green "未检测到常规防火墙，跳过放行步骤"
fi

# 显示访问信息
IP=$(curl -s ipv4.ip.sb)
echo "======================================="
echo "✅ x-ui 安装并设置完成！"
echo "访问地址: http://${IP}:${PORT}"
echo "账户: ${USERNAME}"
echo "密码: ${PASSWORD}"
echo "首次访问可忽略浏览器安全证书警告！"
echo "======================================="

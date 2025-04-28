#!/bin/bash

# 一键安装 x-ui + 自动设置账号密码端口（绕过安全限制，完全自动化）

USERNAME="liang"
PASSWORD="liang"
PORT="2024"

green(){ echo -e "\033[32m$1\033[0m"; }
red(){ echo -e "\033[31m$1\033[0m"; }

[[ $EUID -ne 0 ]] && red "请用root用户运行！" && exit 1

# 更新系统并安装必要软件
if command -v apt &> /dev/null; then
    apt update -y
    apt install -y curl wget sudo socat openssl bash-completion sqlite3
elif command -v yum &> /dev/null; then
    yum update -y
    yum install -y curl wget sudo socat openssl bash-completion sqlite
else
    red "不支持的Linux发行版"
    exit 1
fi

# 安装x-ui
green "开始安装 x-ui..."
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)

# 停止x-ui服务
green "停止x-ui服务以便修改配置文件..."
systemctl stop x-ui

# 修改配置文件中的账号、密码和端口
green "修改配置文件，设置账号密码和端口..."
CONFIG_FILE="/usr/local/x-ui/x-ui.conf"
if [ -f "$CONFIG_FILE" ]; then
    # 通过 sed 命令修改配置文件中的账号、密码和端口
    sed -i "s/\"username\":.*/\"username\": \"${USERNAME}\",/" $CONFIG_FILE
    sed -i "s/\"password\":.*/\"password\": \"${PASSWORD}\",/" $CONFIG_FILE
    sed -i "s/\"port\":.*/\"port\": ${PORT},/" $CONFIG_FILE
else
    red "配置文件不存在，无法修改！"
    exit 1
fi

# 启动x-ui服务并设置开机自启
green "启动x-ui服务并设置开机自启..."
systemctl restart x-ui
systemctl enable x-ui

# 防火墙设置
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

# 显示最终访问信息
IP=$(curl -s ipv4.ip.sb)
echo "======================================="
echo "✅ x-ui 安装并设置完成！"
echo "访问地址: http://${IP}:${PORT}"
echo "账号: ${USERNAME}"
echo "密码: ${PASSWORD}"
echo "首次访问可忽略浏览器安全证书警告！"
echo "======================================="

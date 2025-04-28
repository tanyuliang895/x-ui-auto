#!/bin/bash

# 一键安装/更新 x-ui，并强制设置账号、密码、端口

USERNAME="liang"
PASSWORD="liang"
PORT="2024"

green(){ echo -e "\033[32m$1\033[0m"; }
red(){ echo -e "\033[31m$1\033[0m"; }

[[ $EUID -ne 0 ]] && red "请以root用户运行脚本！" && exit 1

# 更新系统并安装必要依赖
apt update -y && apt install -y curl wget sudo socat openssl bash-completion || yum update -y && yum install -y curl wget sudo socat openssl bash-completion

# 安装/更新 x-ui
green "开始安装/更新 x-ui..."
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)

# 开机自启
systemctl enable x-ui
systemctl restart x-ui

# 强制设置账户、密码、端口
green "强制设置账号、密码、端口..."
if [ -f "/usr/local/x-ui/x-ui" ]; then
    /usr/local/x-ui/x-ui setting -username "${USERNAME}" -password "${PASSWORD}"
    /usr/local/x-ui/x-ui setting -port "${PORT}"
    systemctl restart x-ui
    green "账号密码端口设置完成，已自动重启 x-ui。"
else
    red "x-ui程序未找到，设置失败！"
fi

# 配置防火墙放行端口
green "配置防火墙规则..."
if command -v ufw &> /dev/null; then
    ufw allow "${PORT}/tcp"
    ufw reload
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port="${PORT}/tcp"
    firewall-cmd --reload
else
    green "未检测到常用防火墙，跳过放行步骤。"
fi

# 显示访问信息
IP=$(curl -s ipv4.ip.sb)
echo "======================================="
echo "✅ x-ui 安装/更新并设置完成！"
echo "访问地址: http://${IP}:${PORT}"
echo "账户: ${USERNAME}"
echo "密码: ${PASSWORD}"
echo "======================================="

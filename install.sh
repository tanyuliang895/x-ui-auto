#!/bin/bash

# 一键安装 x-ui + 自动设置账号密码端口（无证书版）

USERNAME="liang"
PASSWORD="liang"
PORT="2024"

green(){ echo -e "\033[32m$1\033[0m"; }
red(){ echo -e "\033[31m$1\033[0m"; }

[[ $EUID -ne 0 ]] && red "请以root用户运行脚本！" && exit 1

# 更新系统并安装必要依赖
if command -v apt &> /dev/null; then
    apt update -y
    apt install -y curl wget sudo socat openssl bash-completion
elif command -v yum &> /dev/null; then
    yum update -y
    yum install -y curl wget sudo socat openssl bash-completion
else
    red "不支持的Linux发行版"
    exit 1
fi

# 安装/更新 x-ui
green "开始安装/更新 x-ui..."
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)

# 设置账号密码端口
green "设置账号密码端口..."
if [ -f "/usr/local/x-ui/x-ui" ]; then
    /usr/local/x-ui/x-ui setting -username "${USERNAME}" -password "${PASSWORD}" -port "${PORT}"
    systemctl enable x-ui
    systemctl restart x-ui
    green "账号密码端口设置完成，x-ui已自动启动！"
else
    red "x-ui程序未找到，设置失败！"
    exit 1
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
    green "未检测到常规防火墙，跳过放行步骤。"
fi

# 显示最终访问信息
IP=$(curl -s ipv4.ip.sb)
echo "======================================="
echo "✅ x-ui 安装并设置完成！"
echo "访问地址: http://${IP}:${PORT}"
echo "账户: ${USERNAME}"
echo "密码: ${PASSWORD}"
echo "======================================="

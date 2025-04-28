#!/bin/bash

# 一键安装x-ui + 自签TLS证书 + 设置账号密码端口
# 用户：tanyuliang895
# 日期：2025-04-28

USERNAME="liang"
PASSWORD="liang"
PORT="2024"

green(){ echo -e "\033[32m$1\033[0m"; }
red(){ echo -e "\033[31m$1\033[0m"; }

[[ $EUID -ne 0 ]] && red "请用root用户运行！" && exit 1

# 更新系统并安装必要软件
apt update -y && apt install -y curl wget sudo socat openssl bash-completion || yum update -y && yum install -y curl wget sudo socat openssl bash-completion

# 创建证书目录并生成自签名证书
mkdir -p /etc/x-ui-cert

green "生成自签TLS证书..."
IP=$(curl -s ipv4.ip.sb)
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -subj "/C=CN/ST=Internet/L=Cloud/O=SelfSigned/OU=IT/CN=${IP}" -keyout /etc/x-ui-cert/private.key -out /etc/x-ui-cert/cert.crt

green "下载安装x-ui面板..."
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)

# 开机启动并启动x-ui
systemctl enable x-ui
systemctl restart x-ui

# 设置账号密码端口和TLS证书（在一次命令中完成）
green "配置账号密码端口及TLS证书..."
x-ui setting -username ${USERNAME} -password ${PASSWORD} -port ${PORT} -cert /etc/x-ui-cert/cert.crt -key /etc/x-ui-cert/private.key -tls true

systemctl restart x-ui

# 配置防火墙开放端口
green "设置防火墙规则..."
if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=${PORT}/tcp
    firewall-cmd --reload
elif command -v ufw &> /dev/null; then
    ufw allow ${PORT}/tcp
    ufw reload
else
    green "未检测到常规防火墙，跳过开放端口步骤"
fi

# 显示最终信息
echo "============================================"
echo "x-ui 安装完成！请使用以下信息访问："
echo "访问地址: https://${IP}:${PORT}"
echo "账号: ${USERNAME}"
echo "密码: ${PASSWORD}"
echo "首次访问请忽略浏览器的安全证书警告，接受继续访问。"
echo "============================================"

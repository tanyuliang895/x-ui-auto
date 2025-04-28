#!/bin/bash

USERNAME="liang"
PASSWORD="liang"
PORT="2024"

green(){ echo -e "\033[32m$1\033[0m"; }
red(){ echo -e "\033[31m$1\033[0m"; }

[[ $EUID -ne 0 ]] && red "请用root用户运行！" && exit 1

# 更新系统并安装必要软件
apt update -y && apt install -y curl wget sudo socat openssl bash-completion || yum update -y && yum install -y curl wget sudo socat openssl bash-completion

# 生成自签名证书
mkdir -p /etc/x-ui-cert
green "生成自签TLS证书..."
IP=$(curl -s ipv4.ip.sb)
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -subj "/C=CN/ST=Internet/L=Cloud/O=SelfSigned/OU=IT/CN=${IP}" \
  -keyout /etc/x-ui-cert/private.key -out /etc/x-ui-cert/cert.crt

# 安装x-ui并等待初始化
green "下载安装x-ui面板..."
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
sleep 10  # 关键修复：等待x-ui初始化完成

# 强制覆盖配置
green "配置账号密码端口及TLS证书..."
/usr/local/x-ui/x-ui setting -username ${USERNAME} -password ${PASSWORD} -port ${PORT} \
  -cert /etc/x-ui-cert/cert.crt -key /etc/x-ui-cert/private.key -tls true

# 重启服务
systemctl enable x-ui
systemctl restart x-ui

# 开放防火墙端口
green "设置防火墙规则..."
if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=${PORT}/tcp
    firewall-cmd --reload
elif command -v ufw &> /dev/null; then
    ufw allow ${PORT}/tcp
    ufw reload
fi

# 显示信息
echo "============================================"
echo "x-ui 安装完成！请使用以下信息访问："
echo "访问地址: https://${IP}:${PORT}"
echo "账号: ${USERNAME}"
echo "密码: ${PASSWORD}"
echo "============================================"

#!/bin/bash
# ---
# 一键安装 X-UI 脚本
# 固定配置：账号 liang / 密码 liang / 端口 2024
# 适用于 Ubuntu/CentOS
# ---

# 禁用交互提示
export DEBIAN_FRONTEND=noninteractive

# 固定配置
USERNAME="liang"
PASSWORD="liang"
PORT="2024"
TLS_DIR="/etc/x-ui/cert"

# 清理旧配置
rm -rf /etc/x-ui/ /usr/local/x-ui/ /etc/systemd/system/x-ui.service

# 静默安装依赖
if grep -q "ubuntu" /etc/os-release; then
    apt update -yq &> /dev/null
    apt install -yq curl wget socat openssl &> /dev/null
else
    yum update -yq &> /dev/null
    yum install -yq curl wget socat openssl &> /dev/null
fi

# 生成自签名证书
mkdir -p $TLS_DIR
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=SelfSigned/CN=$(curl -s ipv4.ip.sb)" \
    -keyout $TLS_DIR/private.key -out $TLS_DIR/cert.crt &> /dev/null

# 强制安装X-UI
bash <(curl -sL https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh) <<EOF
y
EOF

# 写入配置
cat > /etc/x-ui/x-ui.db <<EOF
{
  "web": {
    "username": "$USERNAME",
    "password": "$PASSWORD",
    "port": $PORT,
    "tls": true,
    "cert": "$TLS_DIR/cert.crt",
    "key": "$TLS_DIR/private.key"
  }
}
EOF

# 重启服务
systemctl daemon-reload
systemctl restart x-ui &> /dev/null

# 开放端口
if command -v ufw &> /dev/null; then
    ufw allow $PORT/tcp &> /dev/null
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --add-port=$PORT/tcp --permanent &> /dev/null
    firewall-cmd --reload &> /dev/null
else
    iptables -A INPUT -p tcp --dport $PORT -j ACCEPT &> /dev/null
fi

# 输出结果
IP=$(curl -s ipv4.ip.sb)
echo "========================================"
echo " X-UI 已安装完成！"
echo "========================================"
echo " 面板地址: https://$IP:$PORT"
echo " 账号: $USERNAME"
echo " 密码: $PASSWORD"
echo "========================================"

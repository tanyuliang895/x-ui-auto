#!/bin/bash
# 强制锁定配置：账号=liang 密码=liang 端口=2024

# 固定配置（不可修改）
_USER="liang"
_PASS="liang"
_PORT="2024"
_TLS_DIR="/etc/x-ui/cert"

# --- 核心函数：强制写入配置 ---
force_config() {
    # 删除旧配置
    rm -rf /etc/x-ui /usr/local/x-ui /etc/systemd/system/x-ui.service

    # 安装X-UI（非交互模式）
    echo -e "y\n" | bash <(curl -sL https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)

    # 生成自签名证书
    mkdir -p $_TLS_DIR
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
        -subj "/C=CN/ST=Beijing/O=MyPanel/CN=$(curl -s ipv4.ip.sb)" \
        -keyout $_TLS_DIR/private.key -out $_TLS_DIR/cert.crt &>/dev/null

    # 直接修改数据库文件（绕过x-ui setting命令）
    cat > /etc/x-ui/x-ui.db <<EOF
{
  "web": {
    "username": "$_USER",
    "password": "$_PASS",
    "port": $_PORT,
    "tls": true,
    "cert": "$_TLS_DIR/cert.crt",
    "key": "$_TLS_DIR/private.key"
  }
}
EOF

    # 重启服务并设置防火墙
    systemctl restart x-ui
    if command -v ufw &>/dev/null; then
        ufw allow $_PORT/tcp &>/dev/null
    elif command -v firewall-cmd &>/dev/null; then
        firewall-cmd --add-port=$_PORT/tcp --permanent &>/dev/null
        firewall-cmd --reload &>/dev/null
    else
        iptables -A INPUT -p tcp --dport $_PORT -j ACCEPT &>/dev/null
    fi
}

# --- 主执行流程 ---
echo "正在强制应用配置..."
force_config
echo -e "\033[32m配置已锁定！\033[0m"
echo "账号: $_USER"
echo "密码: $_PASS"
echo "端口: $_PORT"

#!/bin/bash
# X-UI/Xray 服务修复脚本
# 作者：tanyuliang895
# 修复内容：服务无法启动/配置错误/权限问题

# 强制配置参数
USERNAME="liang"
PASSWORD="liang"
PORT="2024"
TLS_DIR="/etc/x-ui/cert"

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
RESET='\033[0m'

# 停止并清理旧服务
echo -e "${YELLOW}[1/7] 正在停止并清理旧服务...${RESET}"
systemctl stop x-ui xray &> /dev/null
killall -9 x-ui xray &> /dev/null
rm -rf /etc/systemd/system/x-ui.service /etc/systemd/system/xray.service
systemctl daemon-reload

# 修复证书权限
echo -e "${YELLOW}[2/7] 修复证书权限...${RESET}"
mkdir -p $TLS_DIR
chmod 700 $TLS_DIR
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -subj "/C=CN/ST=Beijing/O=MyPanel/CN=$(curl -s ipv4.ip.sb)" \
  -keyout $TLS_DIR/private.key \
  -out $TLS_DIR/cert.crt &> /dev/null
chmod 600 $TLS_DIR/*
chown -R nobody:nogroup $TLS_DIR

# 强制重装 X-UI
echo -e "${YELLOW}[3/7] 重新安装 X-UI...${RESET}"
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh) <<< y

# 写入锁定配置
echo -e "${YELLOW}[4/7] 写入防篡改配置...${RESET}"
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

# 修复服务文件
echo -e "${YELLOW}[5/7] 修复 systemd 服务...${RESET}"
cat > /etc/systemd/system/x-ui.service <<EOF
[Unit]
Description=X-UI Service
After=network.target

[Service]
User=root
Group=root
ExecStart=/usr/local/x-ui/x-ui
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# 重启服务
echo -e "${YELLOW}[6/7] 启动服务...${RESET}"
systemctl daemon-reload
systemctl enable x-ui --now &> /dev/null
sleep 5

# 诊断报告
echo -e "${YELLOW}[7/7] 生成诊断报告:${RESET}"
echo "----------------------------------------"
echo -e "X-UI 状态: $(systemctl is-active x-ui)"
echo -e "Xray 状态: $(pgrep xray >/dev/null && echo 正常 || echo 异常)"
echo -e "端口监听: $(ss -tulnp | grep $PORT || echo 未检测到)"
echo -e "防火墙规则:"
iptables -L INPUT -n | grep $PORT || echo -e "${RED}未检测到防火墙规则${RESET}"
echo "----------------------------------------"

# 最终验证
if systemctl is-active --quiet x-ui; then
  echo -e "${GREEN}✅ 服务修复完成！访问地址: https://$(curl -s ipv4.ip.sb):$PORT ${RESET}"
else
  echo -e "${RED}❌ 修复失败，请检查日志: journalctl -u x-ui -n 50 ${RESET}"
fi

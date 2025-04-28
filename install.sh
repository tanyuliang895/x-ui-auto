#!/bin/bash
# 必须用root运行
[ "$(id -u)" != "0" ] && echo "请用root权限执行" && exit 1

# 更新系统，安装依赖
apt update -y
apt install wget curl unzip ufw -y

# 停止并删除旧x-ui服务
systemctl stop x-ui 2>/dev/null
systemctl disable x-ui 2>/dev/null
rm -rf /usr/local/x-ui
rm -f /etc/systemd/system/x-ui.service

# 下载并安装x-ui
mkdir -p /usr/local/x-ui
cd /usr/local/x-ui
wget -N https://github.com/vaxilu/x-ui/releases/download/0.3.3/x-ui-linux-amd64.zip
unzip -o x-ui-linux-amd64.zip
chmod +x x-ui x-ui.sh

# 写入systemd服务
cat > /etc/systemd/system/x-ui.service <<EOF
[Unit]
Description=x-ui Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/x-ui/x-ui
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 启用并启动服务
systemctl daemon-reload
systemctl enable x-ui
systemctl start x-ui

# 设置账号密码端口
/usr/local/x-ui/x-ui setting -username liang -password liang
/usr/local/x-ui/x-ui setting -port 2024

# 开放防火墙端口
ufw allow 2024/tcp
ufw allow 2024/udp
yes | ufw enable

# 重启服务
systemctl restart x-ui

# 显示完成信息
IP=$(curl -s ipinfo.io/ip)
echo -e "\n\033[32m✅ x-ui 全新安装完成！\033[0m"
echo -e "访问地址: http://$IP:2024"
echo -e "账号: liang"
echo -e "密码: liang"

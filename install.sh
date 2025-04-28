#!/bin/bash
# 必须用root运行
[ "$(id -u)" != "0" ] && echo "请用root权限执行" && exit 1

# 备份旧数据
echo "备份现有x-ui数据..."
mkdir -p /root/x-ui-backup
cp -rf /usr/local/x-ui/db/* /root/x-ui-backup/ 2>/dev/null || true

# 更新系统，安装依赖
apt update -y && apt install wget curl unzip ufw -y

# 停止并删除旧服务
systemctl stop x-ui 2>/dev/null
systemctl disable x-ui 2>/dev/null
rm -rf /usr/local/x-ui
rm -f /etc/systemd/system/x-ui.service

# 下载最新x-ui程序
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

# 重新加载服务管理器
systemctl daemon-reload
systemctl enable x-ui
systemctl start x-ui

# 恢复数据
echo "恢复x-ui数据..."
mkdir -p /usr/local/x-ui/db
cp -rf /root/x-ui-backup/* /usr/local/x-ui/db/ 2>/dev/null || true

# 设置账号密码端口
/usr/local/x-ui/x-ui setting -username liang -password liang
/usr/local/x-ui/x-ui setting -port 2024

# 开启防火墙并放行端口
ufw allow 2024/tcp
ufw allow 2024/udp
yes | ufw enable

# 重启x-ui
systemctl restart x-ui

# 删除备份
rm -rf /root/x-ui-backup

# 完成提示
echo -e "\n\033[32m安装完成！\033[0m"
echo -e "管理面板地址: http://$(curl -s ipinfo.io/ip):2024"
echo -e "账号: liang"
echo -e "密码: liang"

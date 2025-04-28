#!/bin/bash
# 必须root权限
[ "$(id -u)" != "0" ] && echo "请用root权限执行" && exit 1

# 更新系统并安装依赖
echo "更新系统，安装必要依赖..."
apt update -y
apt install wget curl unzip ufw -y

# 检查端口2024是否被占用
if lsof -i :2024 &>/dev/null; then
    echo -e "\033[31m⚠️ 警告：端口2024已经被占用，x-ui无法正常启动！\033[0m"
    echo "请释放端口或修改为其他端口。"
    exit 1
else
    echo -e "\033[32m✅ 端口2024空闲，可以继续安装！\033[0m"
fi

# 停止并删除旧服务
echo "停止并删除旧x-ui服务..."
systemctl stop x-ui 2>/dev/null
systemctl disable x-ui 2>/dev/null
rm -rf /usr/local/x-ui
rm -f /etc/systemd/system/x-ui.service

# 下载并安装x-ui
echo "下载并安装x-ui..."
mkdir -p /usr/local/x-ui
cd /usr/local/x-ui
wget -N https://github.com/vaxilu/x-ui/releases/download/0.3.3/x-ui-linux-amd64.zip
unzip -o x-ui-linux-amd64.zip
chmod +x x-ui x-ui.sh

# 创建systemd服务
echo "创建systemd服务..."
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
echo "启用并启动x-ui服务..."
systemctl daemon-reload
systemctl enable x-ui
systemctl start x-ui

# 设置账号密码端口
echo "设置x-ui账号、密码和端口..."
/usr/local/x-ui/x-ui setting -username liang -password liang
/usr/local/x-ui/x-ui setting -port 2024

# 放行防火墙端口
echo "放行防火墙端口2024..."
ufw allow 2024/tcp
ufw allow 2024/udp
yes | ufw enable

# 重启服务
echo "重启x-ui服务..."
systemctl restart x-ui

# 检查x-ui是否启动成功
echo "检查x-ui服务状态..."
if systemctl is-active --quiet x-ui; then
    IP=$(curl -s ipinfo.io/ip)
    echo -e "\n\033[32m✅ x-ui 面板已成功启动！\033[0m"
    echo -e "👉 面板地址：http://$IP:2024"
    echo -e "👉 账号：liang"
    echo -e "👉 密码：liang"
else
    echo -e "\n\033[31m❌ 错误：x-ui 启动失败，请检查系统日志！\033[0m"
    systemctl status x-ui -n 30
fi

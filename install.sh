#!/bin/bash

# 一键安装指定版本的 x-ui (不更新)
# 避免更新 x-ui 面板，避免强制修改密码和端口的提示

USERNAME="liang"
PASSWORD="liang"
PORT="2024"

green(){ echo -e "\033[32m$1\033[0m"; }
red(){ echo -e "\033[31m$1\033[0m"; }

[[ $EUID -ne 0 ]] && red "请用root用户运行！" && exit 1

# 更新系统并安装必要软件
if command -v apt &> /dev/null; then
    apt update -y
    apt install -y curl wget sudo socat openssl bash-completion sqlite3
elif command -v yum &> /dev/null; then
    yum update -y
    yum install -y curl wget sudo socat openssl bash-completion sqlite
else
    red "不支持的Linux发行版"
    exit 1
fi

# 指定版本的 x-ui 安装（避免更新）
XUI_VERSION="v0.9.6"  # 替换为你想要安装的版本
green "开始下载 x-ui ${XUI_VERSION} 安装包..."
wget "https://github.com/vaxilu/x-ui/releases/download/${XUI_VERSION}/x-ui-linux-amd64-${XUI_VERSION}.tar.gz" -O /tmp/x-ui.tar.gz

# 解压并安装
green "解压并安装 x-ui ${XUI_VERSION}..."
tar -zxvf /tmp/x-ui.tar.gz -C /usr/local/
cd /usr/local/x-ui

# 创建配置文件并设置账号密码和端口
green "创建配置文件并设置账号密码和端口..."
cat > /usr/local/x-ui/x-ui.conf <<EOF
{
    "username": "${USERNAME}",
    "password": "${PASSWORD}",
    "port": ${PORT},
    "ssl": false
}
EOF

# 设置服务并启动
green "设置 x-ui 服务..."
chmod +x /usr/local/x-ui/x-ui
cp /usr/local/x-ui/x-ui /usr/bin/x-ui

# 创建系统服务
echo -e "[Unit]
Description=x-ui service
After=network.target

[Service]
ExecStart=/usr/bin/x-ui
Restart=on-failure
LimitNOFILE=4096
User=root

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/x-ui.service

# 启动并设置开机自启
systemctl daemon-reload
systemctl enable x-ui
systemctl start x-ui

# 配置防火墙放行端口
green "配置防火墙放行端口 ${PORT}..."
if command -v ufw &> /dev/null; then
    ufw allow "${PORT}/tcp"
    ufw reload
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port="${PORT}/tcp"
    firewall-cmd --reload
else
    green "未检测到常规防火墙，跳过放行步骤"
fi

# 显示安装信息
IP=$(curl -s ipv4.ip.sb)
echo "======================================="
echo "✅ x-ui ${XUI_VERSION} 安装并设置完成！"
echo "访问地址: http://${IP}:${PORT}"
echo "账号: ${USERNAME}"
echo "密码: ${PASSWORD}"
echo "首次访问可忽略浏览器安全证书警告！"
echo "======================================="

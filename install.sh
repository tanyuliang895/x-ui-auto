#!/bin/bash

# 更新系统
echo "正在更新系统..."
apt update -y && apt upgrade -y

# 安装必备工具
echo "安装curl和wget..."
apt install curl wget ufw -y

# 删除可能已存在的 x-ui 目录
echo "删除旧的x-ui安装目录（如果有的话）..."
rm -rf /usr/local/x-ui

# 下载并安装 x-ui
echo "正在下载并安装x-ui..."
curl -s https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh | bash

# 设置 x-ui 的账号、密码和端口
echo "配置 x-ui 账号、密码和端口..."
x-ui account add liang liang
sed -i 's/"port": 2020/"port": 2024/' /etc/x-ui/x-ui.json

# 启动 x-ui 服务
echo "启动 x-ui 服务..."
systemctl enable x-ui
systemctl start x-ui

# 配置防火墙，允许端口 2024
echo "配置防火墙，允许访问端口 2024..."
ufw allow 2024/tcp
ufw reload

# 完成安装
echo "x-ui 安装完成！"
echo "账号：liang"
echo "密码：liang"
echo "端口：2024"
echo "访问面板地址： http://<服务器IP>:2024"

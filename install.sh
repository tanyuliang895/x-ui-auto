#!/bin/bash

# 更新系统
echo "正在更新系统..."
apt update -y && apt upgrade -y

# 安装必备工具
echo "安装curl和wget..."
apt install curl wget -y

# 下载并安装x-ui
echo "正在下载并安装x-ui..."
curl -s https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh | bash

# 配置x-ui面板
echo "正在配置x-ui账号、密码和端口..."

# 设置账号和密码
x-ui account add liang liang

# 修改端口为2024
sed -i 's/"port": 2020/"port": 2024/' /etc/x-ui/x-ui.json

# 启动x-ui面板
echo "正在启动x-ui面板..."
systemctl enable x-ui
systemctl start x-ui

# 完成安装并输出信息
echo "x-ui安装完成！"
echo "账号：liang"
echo "密码：liang"
echo "端口：2024"
echo "访问面板地址： http://<服务器IP>:2024"

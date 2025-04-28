#!/bin/bash

# 1. 更新系统
echo "正在更新系统..."
apt update -y && apt upgrade -y

# 2. 安装curl、wget和必备依赖
echo "正在安装curl和wget..."
apt install curl wget -y

# 3. 下载并安装x-ui
echo "正在下载并安装x-ui..."
curl -s https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh | bash

# 4. 设置账号和密码
echo "正在设置x-ui的账号和密码..."
x-ui account add liang liang

# 5. 设置x-ui面板端口为2024
echo "正在设置x-ui面板端口为2024..."
sed -i 's/"port": 2020/"port": 2024/' /etc/x-ui/x-ui.json

# 6. 启动x-ui面板
echo "正在启动x-ui面板..."
systemctl enable x-ui
systemctl start x-ui

# 7. 完成安装
echo "x-ui安装完成！"
echo "账号：liang"
echo "密码：liang"
echo "端口：2024"
echo "访问面板地址： http://服务器IP:2024"

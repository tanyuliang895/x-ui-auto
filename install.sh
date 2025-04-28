#!/bin/bash

# 定义变量
USER="liang"
PASSWORD="liang"
PORT="liang"

# 更新系统
echo "更新系统..."
sudo apt update -y
sudo apt upgrade -y

# 安装必要的依赖
echo "安装依赖..."
sudo apt install -y curl unzip

# 下载并安装 x-ui
echo "下载并安装 x-ui..."
cd /usr/local
sudo curl -sSL https://github.com/vaxilu/x-ui/releases/download/1.5.3/x-ui-linux-amd64.zip -o x-ui.zip
sudo unzip x-ui.zip
sudo rm x-ui.zip

# 配置 x-ui
echo "配置 x-ui..."
sudo bash /usr/local/x-ui/x-ui install --user "$USER" --password "$PASSWORD" --port "$PORT"

# 启动 x-ui
echo "启动 x-ui..."
sudo systemctl start x-ui

# 设置开机启动
echo "设置 x-ui 开机启动..."
sudo systemctl enable x-ui

# 输出完成信息
echo "x-ui 安装和配置完成！"
echo "账号: $USER"
echo "密码: $PASSWORD"
echo "端口: $PORT"

#!/bin/bash

# 设置默认用户名、密码和端口
USER="liang"
PASSWORD="liang"
PORT="2024"

# 检查是否是 Ubuntu 22.04
if [[ $(lsb_release -r | awk '{print $2}') != "22.04" ]]; then
    echo "这个脚本只支持 Ubuntu 22.04"
    exit 1
fi

# 更新系统
echo "更新系统..."
sudo apt update && sudo apt upgrade -y

# 安装依赖
echo "安装依赖..."
sudo apt install -y wget curl unzip

# 下载并安装 x-ui
echo "下载并安装 x-ui..."
wget https://github.com/vaxilu/x-ui/releases/download/1.5.5/x-ui-linux-amd64.tar.gz
tar -xzf x-ui-linux-amd64.tar.gz
cd x-ui

# 配置 x-ui
echo "配置 x-ui..."
sudo ./x-ui install
sudo ./x-ui set account "$USER" password "$PASSWORD" port "$PORT"

# 启动 x-ui
echo "启动 x-ui..."
sudo ./x-ui start

echo "安装完成，x-ui 已成功安装并配置。"

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
sudo apt install -y wget curl unzip jq

# 获取最新版本的 x-ui 下载链接
echo "获取最新版本的 x-ui 下载链接..."
LATEST_RELEASE=$(curl -s https://api.github.com/repos/vaxilu/x-ui/releases/latest | jq -r .assets[0].browser_download_url)
if [ -z "$LATEST_RELEASE" ]; then
    echo "获取最新版本失败，请检查 GitHub Release 页面。"
    exit 1
fi

# 下载 x-ui
echo "下载并解压 x-ui..."
wget $LATEST_RELEASE -O x-ui-linux-amd64.tar.gz
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

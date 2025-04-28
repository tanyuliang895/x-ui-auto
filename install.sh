#!/bin/bash

# 脚本必须以root权限运行
if [ "$(id -u)" != "0" ]; then
    echo "请以root权限运行此脚本！"
    exit 1
fi

# 更新系统
apt update -y && apt upgrade -y

# 安装必要软件
apt install -y wget curl unzip

# 停止旧版x-ui
systemctl stop x-ui || true

# 删除旧版x-ui
rm -rf /usr/local/x-ui

# 下载最新版x-ui安装脚本
wget -N --no-check-certificate https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh
chmod +x install.sh

# 安装x-ui
bash install.sh

# 删除下载的安装脚本
rm -f install.sh

# 停止x-ui服务以配置
systemctl stop x-ui

# 配置账号密码端口
/usr/local/x-ui/x-ui setting -username liang -password liang
/usr/local/x-ui/x-ui setting -port 2024

# 开机自启
systemctl enable x-ui

# 重启x-ui服务
systemctl restart x-ui

# 显示安装成功信息
echo -e "\n\033[32m安装完成！\033[0m"
echo -e "管理地址: http://$(curl -s ipinfo.io/ip):2024"
echo -e "账号: liang"
echo -e "密码: liang"


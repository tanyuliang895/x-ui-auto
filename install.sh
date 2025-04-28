#!/bin/bash

# 更新系统并安装必要工具
apt update -y && apt upgrade -y
apt install curl wget -y

# 下载并安装x-ui
curl -s https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh | bash

# 配置x-ui账号、密码和端口
x-ui account add liang liang
sed -i 's/"port": 2020/"port": 2024/' /etc/x-ui/x-ui.json

# 启动并设置开机自启
systemctl enable x-ui
systemctl start x-ui

# 完成
echo "安装完成！"
echo "账号：liang"
echo "密码：liang"
echo "端口：2024"
echo "访问面板： http://<服务器IP>:2024"

#!/bin/bash

# 设置账号、密码和端口
USERNAME="liang"
PASSWORD="liang"
PORT="2024"

echo "账号：$USERNAME"
echo "密码：$PASSWORD"
echo "端口：$PORT"

# 更新系统并安装依赖
sudo apt update && sudo apt install -y wget curl

# 下载 X-UI 安装包
wget https://github.com/vaxilu/x-ui/releases/download/v1.3.3/x-ui-linux-amd64.tar.gz -O /tmp/x-ui.tar.gz

# 解压安装包
tar -xzvf /tmp/x-ui.tar.gz -C /usr/local/bin

# 配置 X-UI 面板
echo "配置 X-UI 面板..."
cat <<EOF > /usr/local/bin/x-ui/config.json
{
  "username": "$USERNAME",
  "password": "$PASSWORD",
  "port": "$PORT"
}
EOF

# 启动 X-UI
/usr/local/bin/x-ui/x-ui

echo "安装完成，X-UI 面板已启动！"
echo "访问地址：http://localhost:$PORT"
echo "账号：$USERNAME"
echo "密码：$PASSWORD"

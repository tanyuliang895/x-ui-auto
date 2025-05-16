#!/bin/bash
# X-UI 一键安装脚本（用户名: liang, 密码: liang, 端口: 2024）
# 用法：bash <(curl -Ls https://raw.githubusercontent.com/tanyuliang895/x-ui-auto/main/install.sh)

# 配置参数（根据你的需求硬编码）
USERNAME="liang"   # 用户名
PASSWORD="liang"   # 密码
PORT="2024"        # 端口

# 自动安装逻辑
set -e  # 任何错误立即终止
echo "🔧 正在安装 X-UI (用户名: $USERNAME, 端口: $PORT)..."

# 依赖检查（自动安装 curl）
if ! command -v curl &> /dev/null; then
  echo "安装依赖: curl..."
  if [ -x "$(command -v apt-get)" ]; then
    sudo apt-get update && sudo apt-get install -y curl
  elif [ -x "$(command -v yum)" ]; then
    sudo yum install -y curl
  else
    echo "❌ 错误：不支持的系统！请手动安装 curl 后重试。"
    exit 1
  fi
fi

# 执行安装命令
bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh) <<EOF
y
$USERNAME
$PASSWORD
$PORT
EOF

# 输出访问信息
echo -e "\n\033[32m✅ 安装完成！\033[0m"
echo "访问地址: http://$(curl -4s icanhazip.com):$PORT"
echo "用户名: $USERNAME"
echo "密码: $PASSWORD"

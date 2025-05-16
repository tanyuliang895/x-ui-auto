#!/bin/bash

# 一键上传脚本到 GitHub
# 作者：你的名字
# 用法：bash upload_to_github.sh

# 设置脚本名称和内容
SCRIPT_NAME="x-ui-install.sh"
SCRIPT_CONTENT='#!/bin/bash
# x-ui 自动安装脚本
# 用户名: liang
# 密码: liang
# 端口: 2024

bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh) <<EOF
y
liang
liang
2024
EOF
'

# 创建脚本文件
echo "$SCRIPT_CONTENT" > "$SCRIPT_NAME"
echo "✅ 脚本文件 $SCRIPT_NAME 已创建！"

# 安装 Git（如果未安装）
if ! command -v git &> /dev/null; then
    echo "🔧 正在安装 Git..."
    sudo apt-get update && sudo apt-get install git -y || { echo "❌ Git 安装失败"; exit 1; }
fi

# 配置 Git 用户信息（如果未配置）
if [ -z "$(git config --global user.name)" ]; then
    read -p "👉 请输入 GitHub 用户名: " GIT_USER
    git config --global user.name "$GIT_USER"
fi

if [ -z "$(git config --global user.email)" ]; then
    read -p "👉 请输入 GitHub 邮箱: " GIT_EMAIL
    git config --global user.email "$GIT_EMAIL"
fi

# 输入 GitHub 仓库信息
read -p "👉 请输入 GitHub 仓库名称（例如 x-ui-scripts）: " REPO_NAME
read -p "👉 请输入仓库描述（可选）: " REPO_DESC

# 创建本地仓库
echo "🚀 正在初始化本地 Git 仓库..."
git init
git add "$SCRIPT_NAME"
git commit -m "添加自动安装脚本"

# 创建 GitHub 仓库并推送
echo "📤 正在上传到 GitHub..."
curl -u "$GIT_USER" https://api.github.com/user/repos -d "{\"name\":\"$REPO_NAME\", \"description\":\"$REPO_DESC\", \"private\":false}" > /dev/null 2>&1
git remote add origin "https://github.com/$GIT_USER/$REPO_NAME.git"
git push -u origin main

echo "🎉 完成！脚本已上传至：https://github.com/$GIT_USER/$REPO_NAME"

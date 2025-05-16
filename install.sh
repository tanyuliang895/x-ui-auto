#!/bin/bash
# 一键上传脚本到 GitHub（修复版）
# 作者：tanyuliang895
# 用法：bash github-upload.sh

# 设置脚本名称和内容（可自定义）
SCRIPT_NAME="install.sh"
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

# ------------------------- 核心逻辑 -------------------------
set -e  # 任何错误立即终止脚本

# 创建脚本文件
echo "$SCRIPT_CONTENT" > "$SCRIPT_NAME"
echo "✅ 脚本文件 $SCRIPT_NAME 已创建！"

# 安装 Git（如果未安装）
if ! command -v git &> /dev/null; then
  echo "🔧 正在安装 Git..."
  sudo apt-get update && sudo apt-get install git -y || { echo "❌ Git 安装失败"; exit 1; }
fi

# 配置 Git 用户信息（强制交互输入）
configure_git_user() {
  if [ -z "$(git config --global user.name)" ]; then
    read -p "👉 请输入 GitHub 用户名: " GIT_USER
    git config --global user.name "$GIT_USER"
  else
    GIT_USER=$(git config --global user.name)
  fi

  if [ -z "$(git config --global user.email)" ]; then
    read -p "👉 请输入 GitHub 邮箱: " GIT_EMAIL
    git config --global user.email "$GIT_EMAIL"
  fi
}
configure_git_user

# 输入仓库信息
read -p "👉 请输入 GitHub 仓库名称（例如 my-x-ui）: " REPO_NAME
read -p "👉 请输入仓库描述（可选）: " REPO_DESC

# 初始化 Git 仓库
echo "🚀 正在初始化仓库..."
git init
git config init.defaultBranch main  # 强制使用 main 分支
git add "$SCRIPT_NAME"
git commit -m "添加自动安装脚本"

# 创建 GitHub 仓库（使用 GitHub API）
echo "📡 正在创建远程仓库..."
curl -u "$GIT_USER" \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/user/repos \
  -d "{\"name\":\"$REPO_NAME\", \"description\":\"$REPO_DESC\", \"private\":false}" > /dev/null 2>&1

# 关联并推送代码
echo "📤 正在上传代码..."
git remote add origin "https://github.com/$GIT_USER/$REPO_NAME.git"
git branch -M main  # 强制重命名分支为 main
git push -u origin main

echo "🎉 完成！脚本已上传至：https://github.com/$GIT_USER/$REPO_NAME"

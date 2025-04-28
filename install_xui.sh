#!/bin/bash

# 智能全自动安装 x-ui + 自动设置账号密码端口
# 作者：tanyuliang895
# 日期：2025-04-28

USERNAME="liang"
PASSWORD="liang"
PORT="2024"

green(){ echo -e "\033[32m$1\033[0m"; }
red(){ echo -e "\033[31m$1\033[0m"; }

# 确保脚本是以root身份运行
[[ $EUID -ne 0 ]] && red "请使用 root 用户运行！" && exit 1

# 检测操作系统类型
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    red "无法识别操作系统类型，退出脚本"
    exit 1
fi

# 获取服务器IP
IP=$(curl -s ipv4.ip.sb || curl -s ipinfo.io/ip)

# 输出欢迎信息
clear
green "============================================"
green "          欢迎使用 x-ui 一键安装脚本"
green "         当前服务器IP: ${IP}"
green "         操作系统: ${PRETTY_NAME:-$OS}"
green "============================================"
echo

# 安装依赖
install_dependencies(){
    if [[ $OS =~ (ubuntu|debian) ]]; then
        apt update -y && apt install -y curl wget sudo socat openssl bash-completion net-tools || {
            red "安装依赖失败，请检查网络连接。"
            exit 1
        }
    elif [[ $OS =~ (centos|rocky|almalinux) ]]; then
        yum update -y && yum install -y curl wget sudo socat openssl bash-completion net-tools || {
            red "安装依赖失败，请检查网络连接。"
            exit 1
        }
    else
        red "暂不支持此操作系统类型：$OS"
        exit 1
    fi
}

# 检测是否已安装 x-ui
if [[ ! -f /usr/local/x-ui/x-ui ]]; then
    green "开始安装 x-ui..."
    bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh) || {
        red "x-ui安装失败，请检查网络或手动安装！"
        exit 1
    }
else
    yellow "检测到 x-ui 已安装，跳过安装步骤。"
fi

# 配置 x-ui 面板
green "自动配置账号、密码、端口..."
/usr/local/x-ui/x-ui setting -username "${USERNAME}" -password "${PASSWORD}" -port "${PORT}"

# 启动并设置 x-ui 开机自启
systemctl enable x-ui
systemctl restart x-ui

# 防火墙配置
green "配置防火墙..."
if command -v ufw &> /dev/null; then
    ufw allow ${PORT}/tcp
    ufw reload
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=${PORT}/tcp
    firewall-cmd --reload
else
    green "未检测到防火墙，跳过防火墙配置。"
fi

# 检查端口是否监听
sleep 2
if ss -lntp | grep ":${PORT}" &> /dev/null; then
    green "✅ 端口 ${PORT} 已成功监听，x-ui启动成功！"
else
    red "❌ 端口 ${PORT} 未监听，请检查 x-ui 服务状态！"
    systemctl status x-ui
fi

# 显示面板信息
echo -e "\n============================================"
green "x-ui 安装完成！面板信息如下："
echo "访问地址: http://${IP}:${PORT}"
echo "账号: ${USERNAME}"
echo "密码: ${PASSWORD}"
echo "============================================"

#!/bin/bash

# 智能全自动安装x-ui（账号密码端口固定，自动适配系统）
# 作者：tanyuliang895
# 日期：2025-04-28

USERNAME="liang"
PASSWORD="liang"
PORT="2024"

green(){ echo -e "\033[32m$1\033[0m"; }
red(){ echo -e "\033[31m$1\033[0m"; }
yellow(){ echo -e "\033[33m$1\033[0m"; }

[[ $EUID -ne 0 ]] && red "请用root用户运行！" && exit 1

# 检测系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    red "无法检测系统类型，退出。"
    exit 1
fi

# 检测IP
IP=$(curl -s ipv4.ip.sb || curl -s ipinfo.io/ip)

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
        apt update -y && apt install -y curl wget sudo socat openssl bash-completion net-tools qrencode
    elif [[ $OS =~ (centos|rocky|almalinux) ]]; then
        yum update -y && yum install -y curl wget sudo socat openssl bash-completion net-tools qrencode
    else
        red "暂不支持此系统：$OS"
        exit 1
    fi
}

# 检测是否已安装x-ui
if [[ -f /usr/local/x-ui/x-ui ]]; then
    yellow "检测到系统已安装 x-ui，跳过安装步骤。"
else
    green "开始安装依赖..."
    install_dependencies

    green "下载安装x-ui..."
    bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh) || {
        red "x-ui安装失败，请检查网络或手动安装！"
        exit 1
    }
fi

systemctl enable x-ui
systemctl restart x-ui

green "自动配置账号、密码、端口..."
/usr/local/x-ui/x-ui setting -username "${USERNAME}" -password "${PASSWORD}"
/usr/local/x-ui/x-ui setting -port "${PORT}"

systemctl restart x-ui

# 防火墙设置
green "配置防火墙..."
if command -v ufw &> /dev/null; then
    ufw allow ${PORT}/tcp
    ufw reload
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=${PORT}/tcp
    firewall-cmd --reload
else
    green "未检测到常规防火墙，跳过防火墙配置。"
fi

# 检测端口监听
sleep 2
if ss -lntp | grep ":${PORT}" &> /dev/null; then
    green "✅ 端口 ${PORT} 已成功监听，x-ui启动成功！"
else
    red "❌ 端口 ${PORT} 未监听，请检查x-ui服务状态！"
    systemctl status x-ui
fi

# 显示登录信息
echo -e "\n============================================"
green "x-ui 安装完成！面板信息如下："
echo "访问地址: http://${IP}:${PORT}"
echo "账号: ${USERNAME}"
echo "密码: ${PASSWORD}"
echo "（直接HTTP访问，无需TLS证书）"
echo "============================================"

# 生成扫码二维码
echo
if command -v qrencode &> /dev/null; then
    green "扫码快速打开面板："
    echo "http://${IP}:${PORT}" | qrencode -o - -t ANSIUTF8
else
    yellow "未检测到qrencode，无法生成二维码。"
fi

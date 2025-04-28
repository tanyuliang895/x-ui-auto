#!/bin/bash

# 一键安装 x-ui 并自动配置证书、账号密码端口
# 作者：tanyuliang895
# 日期：2025-04-28

USERNAME="liang"
PASSWORD="liang"
PORT="2024"

green(){ echo -e "\033[32m$1\033[0m"; }
red(){ echo -e "\033[31m$1\033[0m"; }

# 必须用 root 运行
[[ $EUID -ne 0 ]] && red "请用root用户运行！" && exit 1

# 更新系统并安装必要软件
green "更新系统并安装依赖..."
apt update -y && apt install -y curl wget sudo socat openssl bash-completion net-tools || {
    red "依赖安装失败，请检查网络！"
    exit 1
}

# 创建证书目录
mkdir -p /etc/x-ui-cert

# 获取服务器公网 IP
IP=$(curl -s ipv4.ip.sb || curl -s ipinfo.io/ip)

# 生成自签TLS证书
green "生成自签名TLS证书..."
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -subj "/C=CN/ST=Internet/L=Cloud/O=SelfSigned/OU=IT/CN=${IP}" \
    -keyout /etc/x-ui-cert/private.key \
    -out /etc/x-ui-cert/cert.crt

# 安装x-ui面板
green "下载安装 x-ui 面板..."
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)

# 启动并设置开机自启
systemctl enable x-ui
systemctl restart x-ui

# 配置账号密码端口和TLS证书
green "配置账号、密码、端口及TLS证书..."
/usr/local/x-ui/x-ui setting -username "${USERNAME}" -password "${PASSWORD}"
/usr/local/x-ui/x-ui setting -port "${PORT}"
/usr/local/x-ui/x-ui setting -cert "/etc/x-ui-cert/cert.crt"
/usr/local/x-ui/x-ui setting -key "/etc/x-ui-cert/private.key"
/usr/local/x-ui/x-ui setting -tls true

# 重启x-ui服务
systemctl restart x-ui

# 开放防火墙端口
green "开放防火墙端口..."
if command -v ufw &> /dev/null; then
    ufw allow ${PORT}/tcp
    ufw reload
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=${PORT}/tcp
    firewall-cmd --reload
else
    green "未检测到ufw或firewalld，跳过防火墙配置。"
fi

# 最后输出提示信息
echo -e "\n============================================"
green "x-ui 安装完成！"
echo "访问地址: https://${IP}:${PORT}"
echo "账号: ${USERNAME}"
echo "密码: ${PASSWORD}"
echo "（如果浏览器提示证书不安全，请忽略继续访问）"
echo "============================================"


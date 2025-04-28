#!/bin/bash

# ================================================
# X-UI 全自动管理脚本
# 功能：安装/更新 + 固定账号密码 + 自签证书 + 防火墙
# 作者：tanyuliang895
# ================================================

# 配置区（按需修改）
USERNAME="admin"        # 面板登录账号
PASSWORD="admin@1234"   # 面板登录密码（建议修改）
PORT="2053"             # 面板端口（建议50000以上）
TLS_DOMAIN="auto"       # 证书域名（auto=自动获取IP，或填写自定义域名）

# 全局变量
LOG_FILE="/tmp/x-ui-auto-install.log"
TLS_DIR="/etc/x-ui/cert"

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

# 初始化日志
echo "=== X-UI 安装日志 $(date '+%Y-%m-%d %H:%M:%S') ===" > $LOG_FILE

# 日志记录函数
log() {
    echo -e "$1" | tee -a $LOG_FILE
}

# 错误处理函数
die() {
    log "${RED}[ERROR] $1${RESET}"
    log "${YELLOW}详细日志见：$LOG_FILE${RESET}"
    exit 1
}

# 预检环节
check_root() {
    if [[ $EUID -ne 0 ]]; then
        die "必须使用 root 用户运行此脚本！"
    fi
    log "${GREEN}[1/8] 权限检查通过${RESET}"
}

clean_legacy() {
    log "${BLUE}[2/8] 清理旧版本配置...${RESET}"
    systemctl stop x-ui xray &>> $LOG_FILE
    rm -rf /etc/x-ui /usr/local/x-ui /etc/systemd/system/x-ui.service &>> $LOG_FILE
}

install_deps() {
    log "${BLUE}[3/8] 安装系统依赖...${RESET}"
    if grep -Eqi "ubuntu|debian" /etc/os-release; then
        apt update -y &>> $LOG_FILE || die "系统更新失败"
        apt install -y curl wget socat openssl &>> $LOG_FILE || die "依赖安装失败"
    else
        yum update -y &>> $LOG_FILE || die "系统更新失败"
        yum install -y curl wget socat openssl &>> $LOG_FILE || die "依赖安装失败"
    fi
}

setup_cert() {
    log "${BLUE}[4/8] 配置TLS证书...${RESET}"
    mkdir -p $TLS_DIR
    if [[ "$TLS_DOMAIN" == "auto" ]]; then
        TLS_DOMAIN=$(curl -s ipv4.ip.sb)
    fi

    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
        -subj "/C=US/ST=California/L=San Francisco/O=MyCompany/CN=$TLS_DOMAIN" \
        -keyout $TLS_DIR/private.key \
        -out $TLS_DIR/cert.crt &>> $LOG_FILE || die "证书生成失败"

    chmod 600 $TLS_DIR/* &>> $LOG_FILE
}

install_xui() {
    log "${BLUE}[5/8] 安装/更新X-UI面板...${RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh) &>> $LOG_FILE <<EOF
y
y
EOF

    # 等待服务初始化
    for i in {1..10}; do
        if [[ -f /etc/x-ui/x-ui.db ]]; then
            break
        fi
        sleep 1
    done
}

configure_panel() {
    log "${BLUE}[6/8] 强制应用配置...${RESET}"
    cat > /etc/x-ui/x-ui.db <<EOF
{
  "web": {
    "username": "$USERNAME",
    "password": "$PASSWORD",
    "port": $PORT,
    "tls": true,
    "cert": "$TLS_DIR/cert.crt",
    "key": "$TLS_DIR/private.key"
  }
}
EOF

    # 修复权限
    chown -R x-ui:x-ui /etc/x-ui &>> $LOG_FILE
}

setup_firewall() {
    log "${BLUE}[7/8] 配置防火墙规则...${RESET}"
    if command -v ufw &>> $LOG_FILE; then
        ufw allow $PORT/tcp &>> $LOG_FILE
        ufw reload &>> $LOG_FILE
    elif command -v firewall-cmd &>> $LOG_FILE; then
        firewall-cmd --permanent --add-port=$PORT/tcp &>> $LOG_FILE
        firewall-cmd --reload &>> $LOG_FILE
    else
        iptables -I INPUT -p tcp --dport $PORT -j ACCEPT &>> $LOG_FILE
    fi
}

start_service() {
    log "${BLUE}[8/8] 启动服务...${RESET}"
    systemctl daemon-reload &>> $LOG_FILE
    systemctl enable x-ui &>> $LOG_FILE
    systemctl restart x-ui &>> $LOG_FILE

    # 验证服务状态
    sleep 3
    if ! systemctl is-active --quiet x-ui; then
        die "X-UI服务启动失败，请检查日志"
    fi
}

show_result() {
    clear
    echo -e "${GREEN}
    ██╗  ██╗    ██╗   ██╗██╗
    ╚██╗██╔╝    ╚██╗ ██╔╝██║
     ╚███╔╝      ╚████╔╝ ██║
     ██╔██╗       ╚██╔╝  ██║
    ██╔╝ ██╗       ██║   ██║
    ╚═╝  ╚═╝       ╚═╝   ╚═╝
    ${RESET}"
    echo -e "${GREEN}✅ X-UI 已成功部署！${RESET}"
    echo -e "========================================"
    echo -e "面板地址: ${YELLOW}https://${TLS_DOMAIN}:${PORT}${RESET}"
    echo -e "用户名: ${YELLOW}${USERNAME}${RESET}"
    echo -e "密码: ${YELLOW}${PASSWORD}${RESET}"
    echo -e "========================================"
    echo -e "${BLUE}首次访问需忽略浏览器证书警告${RESET}"
    echo -e "${BLUE}详细日志: ${YELLOW}${LOG_FILE}${RESET}"
}

main() {
    check_root
    clean_legacy
    install_deps
    setup_cert
    install_xui
    configure_panel
    setup_firewall
    start_service
    show_result
}

main

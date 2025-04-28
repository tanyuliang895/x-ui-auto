#!/bin/bash
# X-UI全自动管理脚本
# 仓库地址：https://github.com/tanyuliang895/x-ui-auto
# 最后更新：2024-02-20

# 配置区（按需修改）
PANEL_USER="liang"
PANEL_PASS="liang"
PANEL_PORT="2024"
DOMAIN="rich895.com"
EMAIL="tanyuliang895@gmail.com"
CF_API_KEY="bd10e9aca2a4b3edba843182da0028d2d598f"
CF_DNS_SERVER="vapor.cloudflare.com"  # Cloudflare DNS服务器

# 全局变量
TLS_DIR="/etc/x-ui/ssl"
ACME_DIR="/root/.acme.sh"
LOG_FILE="/var/log/x-ui-auto-install.log"

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

# 初始化日志
echo "=== X-UI安装日志 $(date '+%Y-%m-%d %H:%M:%S') ===" > $LOG_FILE

# 日志记录函数
log() {
    echo -e "$(date "+%Y-%m-%d %H:%M:%S") $1" | tee -a $LOG_FILE
}

# 错误处理函数
die() {
    log "${RED}[ERROR] $1${RESET}"
    log "${YELLOW}详细日志请查看：$LOG_FILE${RESET}"
    exit 1
}

# 预检环节
pre_check() {
    log "${GREEN}[1/8] 执行系统检查..."
    [[ $(id -u) != 0 ]] && die "必须使用root用户运行"
    grep -q "Ubuntu 22.04" /etc/os-release || die "仅支持Ubuntu 22.04系统"
}

# 安装依赖
install_deps() {
    log "${GREEN}[2/8] 安装系统依赖..."
    export DEBIAN_FRONTEND=noninteractive
    apt update -yq &>> $LOG_FILE || die "系统更新失败"
    apt install -yq curl socat openssl ufw jq &>> $LOG_FILE || die "依赖安装失败"
}

# 配置防火墙
setup_firewall() {
    log "${GREEN}[3/8] 配置防火墙规则..."
    ufw allow ssh &>> $LOG_FILE
    ufw allow ${PANEL_PORT}/tcp &>> $LOG_FILE
    echo "y" | ufw enable &>> $LOG_FILE
}

# 安装ACME.sh
install_acme() {
    log "${GREEN}[4/8] 安装ACME证书工具..."
    curl -sL https://get.acme.sh | sh -s email=$EMAIL &>> $LOG_FILE
    source ~/.bashrc
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt &>> $LOG_FILE
}

# 申请SSL证书
issue_cert() {
    log "${GREEN}[5/8] 申请SSL证书..."
    export CF_Key="$CF_API_KEY"
    export CF_Email="$EMAIL"
    
    ~/.acme.sh/acme.sh --issue --dns dns_cf \
        -d $DOMAIN \
        --dnsserver $CF_DNS_SERVER \
        --keylength ec-256 \
        --force &>> $LOG_FILE || die "证书申请失败"

    mkdir -p $TLS_DIR
    ~/.acme.sh/acme.sh --install-cert -d $DOMAIN \
        --ecc \
        --key-file $TLS_DIR/private.key \
        --fullchain-file $TLS_DIR/cert.crt &>> $LOG_FILE
        
    chmod 600 $TLS_DIR/*
}

# 安装/更新X-UI
install_xui() {
    log "${GREEN}[6/8] 安装X-UI面板..."
    bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh) <<EOF &>> $LOG_FILE
y
y
EOF

    log "${GREEN}[7/8] 应用面板配置..."
    cat > /etc/x-ui/x-ui.db <<EOF
{
  "web": {
    "username": "$PANEL_USER",
    "password": "$PANEL_PASS",
    "port": $PANEL_PORT,
    "tls": true,
    "cert": "$TLS_DIR/cert.crt",
    "key": "$TLS_DIR/private.key"
  }
}
EOF
}

# 启动服务
start_service() {
    log "${GREEN}[8/8] 启动系统服务..."
    systemctl daemon-reload &>> $LOG_FILE
    systemctl enable x-ui &>> $LOG_FILE
    systemctl restart x-ui &>> $LOG_FILE || die "服务启动失败"
    
    sleep 2
    if ! systemctl is-active --quiet x-ui; then
        die "X-UI服务未运行，请检查日志"
    fi
}

# 显示结果
show_info() {
    clear
    echo -e "${GREEN}
=============================================
 X-UI 面板已成功部署！
=============================================
 访问地址: ${YELLOW}https://${DOMAIN}:${PANEL_PORT}${GREEN}
 用户名: ${YELLOW}${PANEL_USER}${GREEN}
 密码: ${YELLOW}${PANEL_PASS}${GREEN}
---------------------------------------------
 SSL证书路径: ${YELLOW}${TLS_DIR}${GREEN}
 证书有效期: ${YELLOW}$(~/.acme.sh/acme.sh --list | grep $DOMAIN | awk '{print $10}')${GREEN}
=============================================
${RESET}"
}

# 主流程
main() {
    pre_check
    install_deps
    setup_firewall
    install_acme
    issue_cert
    install_xui
    start_service
    show_info
}

main

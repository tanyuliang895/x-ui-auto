#!/bin/bash

# =============================================
# Ubuntu 专用 X-UI 一键脚本
# 功能：安装/更新 + 固定账号密码 + 自签证书 + 防火墙
# 版本：v2.0
# =============================================

# 固定配置（修改这里！）
USERNAME="admin"        # 面板账号（必须修改）
PASSWORD="admin@2024"   # 面板密码（必须修改）
PORT="2053"             # 面板端口（建议50000以上）

# 全局变量
TLS_DIR="/etc/x-ui/cert"
LOG_FILE="/tmp/x-ui-install.log"

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

# 初始化日志
echo "=== X-UI 安装日志 $(date '+%Y-%m-%d %H:%M:%S') ===" > $LOG_FILE

# 函数：记录日志并显示
log() {
    echo -e "$1" | tee -a $LOG_FILE
}

# 函数：错误处理
die() {
    log "${RED}[ERROR] $1${RESET}"
    log "${YELLOW}详细日志请查看: ${LOG_FILE}${RESET}"
    exit 1
}

# 步骤 1：清理旧版本
clean_legacy() {
    log "${BLUE}[1/6] 清理旧版本和残留文件...${RESET}"
    systemctl stop x-ui xray &>> $LOG_FILE
    rm -rf /etc/x-ui /usr/local/x-ui /etc/systemd/system/x-ui.service &>> $LOG_FILE
}

# 步骤 2：安装依赖
install_deps() {
    log "${BLUE}[2/6] 安装系统依赖...${RESET}"
    apt update -y &>> $LOG_FILE || die "系统更新失败"
    apt install -y curl wget socat openssl &>> $LOG_FILE || die "依赖安装失败"
}

# 步骤 3：生成自签证书
gen_cert() {
    log "${BLUE}[3/6] 生成自签名证书...${RESET}"
    mkdir -p $TLS_DIR
    IP=$(curl -s ipv4.ip.sb)
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
        -subj "/C=US/ST=California/L=San Francisco/O=MyCompany/CN=$IP" \
        -keyout $TLS_DIR/private.key \
        -out $TLS_DIR/cert.crt &>> $LOG_FILE || die "证书生成失败"
    chmod 600 $TLS_DIR/*
}

# 步骤 4：安装 X-UI
install_xui() {
    log "${BLUE}[4/6] 安装/更新 X-UI 面板...${RESET}"
    echo -e "y\ny\n" | bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh) &>> $LOG_FILE
    
    # 等待配置文件生成
    for i in {1..10}; do
        [[ -f /etc/x-ui/x-ui.db ]] && break
        sleep 1
    done
}

# 步骤 5：写入固定配置
force_config() {
    log "${BLUE}[5/6] 写入强制配置...${RESET}"
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
    systemctl daemon-reload &>> $LOG_FILE
}

# 步骤 6：启动服务并放行防火墙
start_service() {
    log "${BLUE}[6/6] 启动服务并配置防火墙...${RESET}"
    systemctl restart x-ui &>> $LOG_FILE || die "服务启动失败"
    ufw allow $PORT/tcp &>> $LOG_FILE
    ufw allow ssh &>> $LOG_FILE
    echo "y" | ufw enable &>> $LOG_FILE
    
    # 验证服务状态
    sleep 3
    if systemctl is-active --quiet x-ui; then
        log "${GREEN}✅ X-UI 服务运行正常！${RESET}"
    else
        die "X-UI 服务未启动，请检查日志"
    fi
}

# 显示结果
show_info() {
    clear
    IP=$(curl -s ipv4.ip.sb)
    echo -e "${GREEN}
=============================================
 X-UI 面板已成功部署！
=============================================
 访问地址: ${YELLOW}https://$IP:$PORT${GREEN}
 账号: ${YELLOW}$USERNAME${GREEN}
 密码: ${YELLOW}$PASSWORD${GREEN}
=============================================
 ${BLUE}首次访问需忽略浏览器证书警告${GREEN}
 日志文件: ${YELLOW}$LOG_FILE${GREEN}
=============================================
${RESET}"
}

# 主流程
main() {
    clean_legacy
    install_deps
    gen_cert
    install_xui
    force_config
    start_service
    show_info
}

main

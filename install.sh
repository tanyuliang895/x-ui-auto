#!/bin/bash
# X-UI 全自动管理脚本
# 作者：tanyuliang895
# 仓库：https://github.com/tanyuliang895/x-ui-auto
# 功能：安装/更新 | SSL证书申请 | 防火墙配置 | 服务监控

# 配置区 (必须修改)
PANEL_USER="liang"                # 面板账号
PANEL_PASS="liang"                # 面板密码
PANEL_PORT="2024"                 # 面板端口
DOMAIN="rich895.com"              # 域名
EMAIL="tanyuliang895@gmail.com"   # 邮箱
CF_API_KEY="bd10e9aca2a4b3edba843182da0028d2d598f"  # Cloudflare API密钥

# 全局配置 (无需修改)
TLS_DIR="/etc/x-ui/tls"           # 证书存储路径
LOG_FILE="/var/log/x-ui-manager.log"  # 日志文件
ACME_SH="/root/.acme.sh/acme.sh"  # ACME路径
CF_DNS_SERVER="vapor.cloudflare.com"  # Cloudflare DNS服务器

# 颜色定义
RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'; BLUE='\033[34m'; RESET='\033[0m'

# 初始化环境
init() {
  echo -e "${GREEN}▶ 初始化系统环境...${RESET}"
  [ $(id -u) != 0 ] && echo -e "${RED}✗ 必须使用root用户${RESET}" && exit 1
  grep -q "Ubuntu 22.04" /etc/os-release || {
    echo -e "${RED}✗ 仅支持Ubuntu 22.04${RESET}"; exit 1
  }
  export DEBIAN_FRONTEND=noninteractive
  mkdir -p $TLS_DIR
  apt clean &> /dev/null
}

# 安装依赖
install_deps() {
  echo -e "${GREEN}▶ 安装系统依赖...${RESET}"
  apt update -yq && apt install -yq \
    curl wget socat openssl jq ufw \
    libnss3-tools cron bash-completion &> $LOG_FILE || {
    echo -e "${RED}✗ 依赖安装失败 (查看日志 $LOG_FILE)${RESET}"; exit 1
  }
}

# 配置防火墙
setup_firewall() {
  echo -e "${GREEN}▶ 配置防火墙规则...${RESET}"
  ufw allow $PANEL_PORT/tcp &>> $LOG_FILE
  ufw allow ssh &>> $LOG_FILE
  echo "y" | ufw enable &>> $LOG_FILE
}

# 安装ACME
install_acme() {
  echo -e "${GREEN}▶ 安装证书工具...${RESET}"
  curl -sL https://get.acme.sh | sh -s email=$EMAIL &>> $LOG_FILE
  [ ! -f "$ACME_SH" ] && {
    echo -e "${RED}✗ ACME安装失败${RESET}"; exit 1
  }
  $ACME_SH --set-default-ca --server letsencrypt &>> $LOG_FILE
}

# 申请证书
issue_cert() {
  echo -e "${GREEN}▶ 申请SSL证书...${RESET}"
  export CF_Key="$CF_API_KEY"
  export CF_Email="$EMAIL"
  
  $ACME_SH --issue --dns dns_cf \
    -d $DOMAIN \
    --dnsserver $CF_DNS_SERVER \
    --keylength ec-256 \
    --force &>> $LOG_FILE || {
    echo -e "${RED}✗ 证书申请失败 (检查DNS解析)${RESET}"; exit 1
  }

  $ACME_SH --install-cert -d $DOMAIN --ecc \
    --key-file $TLS_DIR/private.key \
    --fullchain-file $TLS_DIR/cert.crt &>> $LOG_FILE
    
  chmod 600 $TLS_DIR/*
}

# 安装/更新X-UI
manage_xui() {
  echo -e "${GREEN}▶ 管理X-UI服务...${RESET}"
  systemctl stop x-ui &> /dev/null
  
  # 安装/更新
  bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh) <<EOF &>> $LOG_FILE
y
y
EOF

  # 应用配置
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

  # 重启服务
  systemctl daemon-reload &>> $LOG_FILE
  systemctl enable x-ui &>> $LOG_FILE
  systemctl restart x-ui &>> $LOG_FILE || {
    echo -e "${RED}✗ 服务启动失败${RESET}";
    journalctl -u x-ui -n 20 --no-pager
    exit 1
  }
}

# 监控服务状态
monitor_service() {
  if ! systemctl is-active --quiet x-ui; then
    echo -e "${YELLOW}⚠ 检测到服务异常，尝试恢复...${RESET}"
    systemctl restart x-ui &>> $LOG_FILE
    sleep 3
    systemctl is-active --quiet x-ui || {
      echo -e "${RED}✗ 服务恢复失败，请检查配置${RESET}"
      exit 1
    }
  fi
}

# 显示信息
show_info() {
  clear
  echo -e "${GREEN}"
  echo "================================================"
  echo " X-UI 管理完成"
  echo "================================================"
  echo -e " 访问地址: ${YELLOW}https://$DOMAIN:$PANEL_PORT${GREEN}"
  echo -e " 用户名: ${YELLOW}$PANEL_USER${GREEN}"
  echo -e " 密码: ${YELLOW}$PANEL_PASS${GREEN}"
  echo "------------------------------------------------"
  echo -e " 证书有效期: ${YELLOW}$($ACME_SH --list | grep $DOMAIN | awk '{print $10}')${GREEN}"
  echo -e " 自动续期状态: ${YELLOW}$($ACME_SH --cron -f 2>&1 | grep 'Cert success')${GREEN}"
  echo "================================================"
  echo -e "${RESET}"
}

# 主流程
main() {
  init
  install_deps
  setup_firewall
  install_acme
  issue_cert
  manage_xui
  monitor_service
  show_info
}

# 执行主程序
main

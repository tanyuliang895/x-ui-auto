#!/bin/bash

# 一键配置x-ui面板（Ubuntu系统+默认SSH 22端口）
# 账号：liang 密码：liang 端口：2024

if [ "$(id -u)" != "0" ]; then
    echo "必须使用root权限运行，请执行 sudo bash $0"
    exit 1
fi

# 禁用首次登录强制修改
export SKIP_FIRST_LOGIN=1

# 系统更新与依赖安装
apt update && apt upgrade -y
apt install -y curl sqlite3 ufw

# 自动安装x-ui（国内镜像加速）
bash <(curl -Ls https://fastly.jsdelivr.net/gh/vaxilu/x-ui@master/install.sh) --no-password

# 生成密码哈希（使用x-ui专用算法）
XUI_HASH=$(echo -n "liang" | x-ui hash | awk '{print $3}')

# 修改数据库配置
SQLITE_DB="/etc/x-ui/x-ui.db"
sqlite3 "$SQLITE_DB" <<EOF
UPDATE users SET username='liang', password='$XUI_HASH' WHERE id=1;
UPDATE setting SET value='2024' WHERE key='web_port';
INSERT INTO system (key, value) VALUES ('force_update_creds', 'false');
COMMIT;
EOF

# 智能防火墙配置（同时放行SSH 22和面板2024端口）
{
    ufw allow 22/tcp       # 保留默认SSH端口
    ufw allow 2024/tcp     # 新增面板端口
    ufw --force enable     # 启用防火墙但不影响现有连接
} >/dev/null 2>&1

# 服务管理
systemctl daemon-reload
systemctl restart x-ui

# 显示访问信息
clear
echo "╔══════════════════════════════╗"
echo "║    X-UI 安全配置已完成       ║"
echo "╠══════════════════════════════╣"
echo "║ 访问地址: http://$(curl -s4 ifconfig.io):2024"
echo "║ 登录账号: liang               ║"
echo "║ 登录密码: liang               ║"
echo "╠══════════════════════════════╣"
echo "║ * 已放行端口：               ║"
echo "║   - SSH (22/tcp)             ║"
echo "║   - X-UI Panel (2024/tcp)    ║"
echo "╚══════════════════════════════╝"

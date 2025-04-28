#!/bin/bash
# Auto Install x-ui with Full Configuration (终极优化版)
# 仓库地址: https://github.com/tanyuliang895/x-ui-auto

# 输入参数设置
XUI_USER="${1:-liang}"     # 默认用户名 liang
XUI_PASS="${2:-liang}"     # 默认密码 liang
XUI_PORT="${3:-2024}"      # 默认端口 2024

# 依赖安装
sudo apt update && sudo apt install -y curl expect sqlite3 ufw

# 自动化安装阶段
curl -sL https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh -o x-ui_install.sh

sudo expect <<EOF
spawn bash x-ui_install.sh
expect "是否继续安装*" { send "y\r" }
expect "请输入面板端口*" { send "$XUI_PORT\r" }
expect "请输入面板账号*" { send "$XUI_USER\r" }
expect "请输入面板密码*" { send "$XUI_PASS\r" }
expect eof
EOF

# 防覆盖加固
sudo sqlite3 /etc/x-ui/x-ui.db <<SQL
INSERT OR REPLACE INTO setting (key, value) VALUES 
  ('install_time', '2099-01-01'),
  ('force_reset', 'false');
UPDATE user SET password='$(echo -n "$XUI_PASS" | sha256sum | awk '{print $1}');
SQL

# 服务管理
sudo systemctl restart x-ui
sudo ufw allow $XUI_PORT/tcp
sudo ufw --force enable

# 状态验证
echo "=== 安装验证 ==="
echo -n "服务状态: " && systemctl is-active x-ui
echo -n "端口监听: " && sudo ss -tlnp | grep ":$XUI_PORT"
echo "访问地址: http://$(curl -s ifconfig.me):$XUI_PORT"

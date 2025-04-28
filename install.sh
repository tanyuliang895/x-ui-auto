#!/bin/bash

# 参数定义
USERNAME="liang"
PASSWORD="liang"
PORT="2024"

# 安装依赖
sudo apt update && sudo apt install -y expect sqlite3

# 自动化安装流程
curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh -o x-ui_install.sh

sudo expect <<EOF
spawn bash x-ui_install.sh
# 处理所有可能出现的交互提示
expect {
  "确认是否继续?*" { send "y\r"; exp_continue }
  "请输入面板端口*" { send "$PORT\r"; exp_continue }
  "请输入面板账号*" { send "$USERNAME\r"; exp_continue }
  "请输入面板密码*" { send "$PASSWORD\r"; exp_continue }
  eof
}
EOF

# 绕过安全机制
sudo sqlite3 /etc/x-ui/x-ui.db <<SQL
INSERT OR REPLACE INTO setting (key, value) VALUES
  ('install_time', '2099-01-01'),
  ('force_reset', 'false');
UPDATE user SET password='$(echo -n "$PASSWORD" | sha256sum | awk '{print $1}');
SQL

# 重启服务
sudo systemctl restart x-ui

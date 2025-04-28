#!/bin/bash
# 终极优化版脚本（增加错误处理与日志记录）
LOG_FILE="/tmp/x-ui-install.log"

# 函数：错误中断处理
function handle_error {
    echo "安装失败！查看日志: $LOG_FILE"
    exit 1
}

trap handle_error ERR

# 步骤1：系统准备
sudo apt update >> $LOG_FILE 2>&1
sudo apt install -y curl expect sqlite3 ufw >> $LOG_FILE 2>&1

# 步骤2：交互式参数收集
read -p "请输入用户名 (默认liang): " USERNAME
USERNAME=${USERNAME:-liang}
read -sp "请输入密码 (默认liang): " PASSWORD
PASSWORD=${PASSWORD:-liang}
echo
read -p "请输入端口 (默认2024): " PORT
PORT=${PORT:-2024}

# 步骤3：自动化安装
curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh -o x-ui_install.sh
sudo expect <<EOF >> $LOG_FILE 2>&1
spawn bash x-ui_install.sh
expect "是否继续安装*" { send "y\r" }
expect "请输入面板端口*" { send "$PORT\r" }
expect "请输入面板账号*" { send "$USERNAME\r" }
expect "请输入面板密码*" { send "$PASSWORD\r" }
expect eof
EOF

# 步骤4：防覆盖加固
sudo sqlite3 /etc/x-ui/x-ui.db <<SQL
UPDATE user SET password='$(echo -n "$PASSWORD" | sha256sum | awk '{print $1}')';
UPDATE setting SET value='$PORT' WHERE key='webPort';
INSERT INTO setting (key, value) VALUES ('install_time', '2099-01-01') ON CONFLICT(key) DO UPDATE SET value='2099-01-01';
SQL

# 步骤5：服务验证
sudo systemctl restart x-ui
if ! systemctl is-active --quiet x-ui; then
    echo "[错误] x-ui 服务未启动！"
    journalctl -u x-ui -n 50 >> $LOG_FILE
    handle_error
fi

# 结果输出
echo "================================"
echo "✅ 安装成功！验证信息："
echo "地址: $(curl -s ifconfig.me)"
echo "端口: $PORT"
echo "账号: $USERNAME"
echo "密码: $(sed 's/./*/g' <<< "$PASSWORD")"
echo "================================"

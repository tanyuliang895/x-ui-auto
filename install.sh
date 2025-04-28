#!/bin/bash

# 完全清除x-ui配置脚本（Ubuntu系统）

if [ "$(id -u)" != "0" ]; then
    echo "必须使用root权限运行，请执行 sudo bash $0"
    exit 1
fi

# 停止服务并禁用
systemctl stop x-ui 2>/dev/null
systemctl disable x-ui 2>/dev/null

# 删除核心文件
rm -rfv /etc/x-ui/  # 配置文件目录
rm -rfv /usr/local/x-ui/  # 程序主目录
rm -fv /etc/systemd/system/x-ui.service  # 服务文件

# 清除日志文件
journalctl --rotate  # 日志轮转
journalctl --vacuum-time=1s --quiet  # 清除所有日志
rm -rfv /var/log/x-ui/  # 专用日志目录

# 删除防火墙规则（自动检测端口）
CURRENT_PORT=$(sqlite3 /etc/x-ui/x-ui.db "SELECT value FROM setting WHERE key='web_port';" 2>/dev/null)
if [ -n "$CURRENT_PORT" ]; then
    ufw delete allow ${CURRENT_PORT}/tcp
    echo "已移除防火墙 ${CURRENT_PORT} 端口规则"
fi

# 清理残留进程
pkill -9 x-ui 2>/dev/null

# 重新加载服务配置
systemctl daemon-reload
systemctl reset-failed

# 确认清理结果
echo -e "\n[验证结果]"
echo "残留文件检查："
find / -name "*x-ui*" 2>/dev/null | grep -vE '/proc|/sys|/dev'

echo -e "\n[清理完成] 所有x-ui配置已清除"

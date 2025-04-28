#!/bin/bash
# x-ui 完全重置脚本（Ubuntu）
# 功能：清除所有配置、文件、端口规则及服务残留

# 强制停止并移除服务
sudo systemctl stop x-ui 2>/dev/null
sudo systemctl disable x-ui 2>/dev/null
sudo rm -f /etc/systemd/system/x-ui.service

# 删除所有相关文件（覆盖已知安装路径）
sudo rm -rf \
  /etc/x-ui \
  /usr/local/x-ui \
  /var/log/x-ui.log \
  ~/x-ui* \
  /tmp/x-ui*

# 清理防火墙规则（自动适配2024端口）
sudo ufw delete allow 2024/tcp 2>/dev/null
sudo ufw --force reload

# 深度清理残留配置
sudo find /etc -name "*x-ui*" -exec rm -rf {} \; 2>/dev/null
sudo find /var/lib -name "*x-ui*" -exec rm -rf {} \; 2>/dev/null

# 重置系统服务状态
sudo systemctl daemon-reload
sudo systemctl reset-failed

# 可选：移除依赖包（默认注释）
# sudo apt remove -y --purge sqlite3 expect 2>/dev/null

# 验证清理结果
echo "================验证报告================"
echo "[服务状态] $(systemctl is-active x-ui 2>/dev/null || echo '服务未运行')"
echo "[残留文件] $(ls /etc/x-ui 2>/dev/null || echo '无配置文件残留')"
echo "[端口监听] $(ss -tunlp | grep :2024 || echo '无端口占用')"
echo "========================================"

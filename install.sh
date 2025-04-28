#!/bin/bash
# x-ui 完全卸载清理脚本（Ubuntu）

# 停止并禁用服务
sudo systemctl stop x-ui 2>/dev/null
sudo systemctl disable x-ui 2>/dev/null

# 删除相关文件
sudo rm -rf /etc/x-ui              # 配置文件目录
sudo rm -f /usr/local/x-ui         # 主程序目录
sudo rm -f /etc/systemd/system/x-ui.service  # 服务文件

# 清理防火墙规则
sudo ufw delete allow 2024/tcp 2>/dev/null   # 根据实际端口修改
sudo ufw --force reload

# 删除日志文件
sudo journalctl --vacuum-time=1d    # 清理1天前的日志
sudo rm -f /var/log/x-ui.log 2>/dev/null

# 删除安装脚本残留
rm -f x-ui_install.sh 2>/dev/null

# 重置系统配置
sudo systemctl daemon-reload
sudo systemctl reset-failed

# 可选：移除依赖包（谨慎操作）
# sudo apt remove -y --purge sqlite3 expect 2>/dev/null

echo "================================"
echo "✅ 已执行深度清理！残留痕迹检查："
echo "服务状态: $(systemctl is-active x-ui 2>/dev/null || echo '未运行')"
echo "残留文件: $(ls /etc/x-ui 2>/dev/null || echo '无')"
echo "端口监听: $(ss -tunlp | grep 2024 || echo '无')"
echo "================================"

#!/bin/bash
# 必须root运行
[ "$(id -u)" != "0" ] && echo "请用root权限执行" && exit 1

# 更新
apt update -y

# 安装必要工具
apt install wget curl -y

# 停止旧x-ui
systemctl stop x-ui 2>/dev/null

# 删除旧版
rm -rf /usr/local/x-ui

# 下载并安装x-ui
wget -N --no-check-certificate https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh && chmod +x install.sh && bash install.sh && rm -f install.sh

# 配置账号密码端口
/usr/local/x-ui/x-ui setting -username liang -password liang
/usr/local/x-ui/x-ui setting -port 2024

# 设置开机启动并重启服务
systemctl enable x-ui
systemctl restart x-ui

# 显示简单提示
echo -e "\n安装完成！账号: liang 密码: liang 端口: 2024"

#!/bin/bash

# https://www.wireguard.com/install/

# 高速新VPN协议WireGuard服务端一键脚本
# GCP香港  和 Vutrl  搬瓦工 测试可用，已经添加自动判断网卡名
# OpenVZ  PVE 不能用

# Windows TunSafe版客户端
# https://tunsafe.com/download

# Debian9  安装 WireGuard 步骤

debian_wireguard_install(){

# Debian 默认往往都没有 linux-headers 内核，而安装使用 WireGuard 必须要

# 更新软件包源
apt update

# 安装和 linux-image 内核版本相对于的 linux-headers 内核
apt install linux-headers-$(uname -r) -y

# Debian9 安装后内核列表
dpkg -l|grep linux-headers

# 安装WireGuard
# 添加 unstable 软件包源，以确保安装版本是最新的
echo "deb http://deb.debian.org/debian/ unstable main" > /etc/apt/sources.list.d/unstable.list
printf 'Package: *\nPin: release a=unstable\nPin-Priority: 90\n' > /etc/apt/preferences.d/limit-unstable

# 更新一下软件包源
apt update

# 开始安装 WireGuard ，和辅助库 resolvconf
apt install wireguard resolvconf -y

# 验证是否安装成功
modprobe wireguard && lsmod | grep wireguard

# 配置步骤 WireGuard服务端

# 首先进入配置文件目录
mkdir -p /etc/wireguard
cd /etc/wireguard

# 然后开始生成 密匙对(公匙+私匙)。
wg genkey | tee sprivatekey | wg pubkey > spublickey
wg genkey | tee cprivatekey | wg pubkey > cpublickey

# 获得服务器ip
serverip=$(curl -4 ip.sb)

# 生成服务端配置文件
echo "[Interface]
# 私匙，自动读取上面刚刚生成的密匙内容
PrivateKey = $(cat sprivatekey)

# VPN中本机的内网IP，一般默认即可，除非和你服务器或客户端设备本地网段冲突
Address = 10.0.0.1/24

# 运行 WireGuard 时要执行的 iptables 防火墙规则，用于打开NAT转发之类的。
# 如果你的服务器主网卡名称不是 eth0 ，那么请修改下面防火墙规则中最后的 eth0 为你的主网卡名称。
PostUp   = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# 停止 WireGuard 时要执行的 iptables 防火墙规则，用于关闭NAT转发之类的。
# 如果你的服务器主网卡名称不是 eth0 ，那么请修改下面防火墙规则中最后的 eth0 为你的主网卡名称。
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# 服务端监听端口，可以自行修改
ListenPort = 9999

# 服务端请求域名解析 DNS
DNS = 8.8.8.8

# 保持默认
MTU = 1420

[Peer]
# 公匙，自动读取上面刚刚生成的密匙内容
PublicKey = $(cat cpublickey)

# VPN内网IP范围，一般默认即可，除非和你服务器或客户端设备本地网段冲突
AllowedIPs = 10.0.0.2/32" > wg0.conf

# 生成客户端配置文件
echo "[Interface]
# 私匙，自动读取上面刚刚生成的密匙内容
PrivateKey = $(cat cprivatekey)

# VPN内网IP范围
Address = 10.0.0.2/24

# 解析域名用的DNS
DNS = 8.8.8.8

# 保持默认
MTU = 1300

# Wireguard客户端配置文件加入PreUp,Postdown命令调用批处理文件
PreUp = start   .\route\routes-up.bat
PostDown = start  .\route\routes-down.bat

#### 正常使用Tunsafe点击connect就会调用routes-up.bat将国内IP写进系统路由表，断开disconnect则会调用routes-down.bat删除路由表。
#### 连接成功后可上 http://ip111.cn/ 测试自己的IP。

[Peer]
# 公匙，自动读取上面刚刚生成的密匙内容
PublicKey = $(cat spublickey)

# 服务器地址和端口，下面的 X.X.X.X 记得更换为你的服务器公网IP，端口根据服务端配置时的监听端口填写
Endpoint = $serverip:9009

# 转发流量的IP范围，下面这个代表所有流量都走VPN
AllowedIPs = 0.0.0.0/0, ::0/0

# 保持连接，如果客户端或服务端是 NAT 网络(比如国内大多数家庭宽带没有公网IP，都是NAT)，
# 那么就需要添加这个参数定时链接服务端(单位：秒)，如果你的服务器和你本地都不是 NAT 网络，
# 那么建议不使用该参数（设置为0，或客户端配置文件中删除这行）

PersistentKeepalive = 25"|sed '/^#/d;/^\s*$/d' > client.conf

# 赋予配置文件夹权限
chmod 777 -R /etc/wireguard

sysctl_config() {
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
    echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
    sysctl -p >/dev/null 2>&1
}

# 开启 BBR
sysctl_config
lsmod | grep bbr

# 打开防火墙转发功能
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

# 启动WireGuard
wg-quick up wg0

# 设置开机启动
systemctl enable wg-quick@wg0

# 查询WireGuard状态
wg

# 以上配置文本只做参考文档使用，实际生成 WireGuard 多用户配置

# 一键 WireGuard 多用户配置共享脚本
wget -qO- https://git.io/fpnQt | bash

}
# ======= 容错：检查系统，调用 Ubuntu Centos 系统对应安装脚本 ========
check_sys(){
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
    elif cat /etc/issue | grep -q -E -i "debian"; then
        release="debian"
    elif cat /etc/issue | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    elif cat /proc/version | grep -q -E -i "debian"; then
        release="debian"
    elif cat /proc/version | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    fi
    bit=`uname -m`
}

wireguard_config(){
    if [[ ${release} == "centos" ]]; then
    	yum install -y wget vim curl
        # CentOS 7 一键脚本安装WireGuard  (官方脚本自动升级内核)
		wget -qO- git.io/fhnhS | bash
    fi

    if [[ ${release} == "ubuntu" ]]; then
        # 一键安装wireguard 脚本 Ubuntu   (源:逗比网安装笔记)
		wget -qO- git.io/fpcnL | bash
    fi

    if [[ ${release} == "debian" ]]; then
        debian_wireguard_install
    fi
}


check_sys && wireguard_config

# Step 1. Execute scripts below on remote VPS CentOS 8 recommeded

```shell
dnf install -y epel-release
dnf config-manager --set-enabled PowerTools
dnf copr enable jdoss/wireguard -y
dnf install -y wireguard-dkms wireguard-tools
dnf install -y dnf-automatic
sed -i 's/apply_updates = no/apply_updates = yes/' /etc/dnf/automatic.conf
systemctl enable --now dnf-automatic.timer
```


```shell
vim /etc/sysctl.conf
```
add content below:
```
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.ip_forward = 1
net.ipv4.tcp_syncookies = 1
```
```shell
sysctl -p
```
mkdir & generate keys
```shell
mkdir /etc/wireguard && cd /etc/wireguard
bash -c 'umask 077; touch wg0.conf'
wg genkey | tee server_privatekey | wg pubkey > publickey
cat publickey
cat server_privatekey
```
config virtual network interface
```shell
vim /etc/wireguard/wg0.conf 
```
add
```
[Interface]
Address = 10.0.0.1/24  # This is the virtual IP address, with the subnet mask we will use for the VPN
PostUp   = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
ListenPort = 51820
PrivateKey = [SERVER PRIVATE KEY]

[Peer]
PublicKey = [CLIENT PUBLIC KEY]
AllowedIPs = 10.0.0.2/32  # 这表示客户端只有一个 ip。
```

client config
```
[Interface]
Address = 10.0.0.2/24  # The client IP from wg0server.conf with the same subnet mask
PrivateKey = [CLIENT PRIVATE KEY]
DNS = 10.0.0.1

[Peer]
PublicKey = [SERVER PUBLICKEY]
AllowedIPs = 0.0.0.0/0, ::0/0
Endpoint = [SERVER ENDPOINT]:51820
PersistentKeepalive = 25
```

enable service
```shell
systemctl enable wg-quick@wg0.service
systemctl restart wg-quick@wg0.service
```

check listner port

```shell
wg
```
使用 `wg-quick up wg0` 来启用 Interface, 使用 `wg-quick down wg0` 来关闭。

使用 `systemctl enable wg-quick@wg0` 来自动启动。


# Step 2. On remote server. Run speederv2 server side.
```shell
nohup ./speederv2 -s -l0.0.0.0:9999 -r127.0.0.1:53517 -k  "your_password" --mode 0 -f2:4 -q1 >speeder.log 2>&1 &
```
Open port 9999/udp


# Step 3. On jump server. Run speederv2 client side.
```shell
nohup ./speederv2 -c -l0.0.0.0:9898 -r代理服务器IP:9999 -k "your_password" --mode 0 -f2:4 -q1 >speeder.log 2>&1 &
```

# Step 4. On mac change wg ip port to jump server ip:9898


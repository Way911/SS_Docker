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
Address = 192.168.2.1/24    #address of virtual network interface
DNS = 8.8.8.8
MTU = 1420
ListenPort = 57000
SaveConfig = true
PrivateKey = GBu3qlu1ZbPVF4UZIVh9EmtVp7dB5Pe8gFvubg99H08=   #replace it with server private key
```

check listner port

```shell
wg
```

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


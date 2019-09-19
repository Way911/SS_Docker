# Step 1. Execute scripts below on remote VPS.

```shell
./wireguard_install.sh
```

check listner port

```shell
wg
```

# Step 2. On remote server. Run speederv2 server side.
Notice port 53517, chage it to your wg port
```shell
nohup ./speederv2 -s -l0.0.0.0:9999 -r127.0.0.1:53517 -k  "your_password" --mode 0 -f2:4 -q1 >speeder.log 2>&1 &
```
Open port 9999/udp


# Step 3. On jump server. Run speederv2 client side.
```shell
nohup ./speederv2 -c -l0.0.0.0:9898 -r代理服务器IP:9999 -k "your_password" --mode 0 -f2:4 -q1 >speeder.log 2>&1 &
```

# Step 4. On mac change wg ip port to jump server ip:9898


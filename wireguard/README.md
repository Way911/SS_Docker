# Step 1. Execute scripts below on remote VPS.

```shell
./wireguard_install.sh
```

check listner port

```shell
wg
```

# Step 2. On jump server
Notice port 53517, chage it to your wg port
```shell
nohup ./speederv2 -s -l0.0.0.0:9999 -r127.0.0.1:53517 -k  "your_password" --mode 0 -f2:4 -q1 >speeder.log 2>&1 &
```

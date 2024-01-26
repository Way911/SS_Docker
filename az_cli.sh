az container create --resource-group ss --name ss --image shadowsocks/shadowsocks-libev --ports 8388 --environment-variables PASSWORD=March2022! --cpu 1 --memory 1 --dns-name-label sscontainer

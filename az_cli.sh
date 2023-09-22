# https://learn.microsoft.com/en-us/azure/container-apps/vnet-custom?tabs=bash%2Cazure-cli&pivots=azure-cli
az container create --resource-group ss --name ss --image shadowsocks/shadowsocks-libev --ports 8388 --environment-variables PASSWORD=March2022!

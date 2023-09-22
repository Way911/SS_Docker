# https://learn.microsoft.com/en-us/azure/container-apps/vnet-custom?tabs=bash%2Cazure-cli&pivots=azure-cli

RESOURCE_GROUP="ss-container"
LOCATION="southeastasia"
CONTAINERAPPS_ENVIRONMENT="ss-container-environment"

az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

VNET_NAME="ss-vnet"

az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --location $LOCATION \
  --address-prefix 10.0.0.0/16

az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name infrastructure-subnet \
  --address-prefixes 10.0.0.0/21

INFRASTRUCTURE_SUBNET=`az network vnet subnet show --resource-group ${RESOURCE_GROUP} --vnet-name $VNET_NAME --name infrastructure-subnet --query "id" -o tsv | tr -d '[:space:]'`

az containerapp env create \
  --name $CONTAINERAPPS_ENVIRONMENT \
  --resource-group $RESOURCE_GROUP \
  --location "$LOCATION" \
  --infrastructure-subnet-resource-id $INFRASTRUCTURE_SUBNET

ENVIRONMENT_DEFAULT_DOMAIN=`az containerapp env show --name ${CONTAINERAPPS_ENVIRONMENT} --resource-group ${RESOURCE_GROUP} --query properties.defaultDomain --out json | tr -d '"'`

ENVIRONMENT_STATIC_IP=`az containerapp env show --name ${CONTAINERAPPS_ENVIRONMENT} --resource-group ${RESOURCE_GROUP} --query properties.staticIp --out json | tr -d '"'`

VNET_ID=`az network vnet show --resource-group ${RESOURCE_GROUP} --name ${VNET_NAME} --query id --out json | tr -d '"'`

# az containerapp create \
#   --name ss \
#   --resource-group $RESOURCE_GROUP \
#   --environment $CONTAINERAPPS_ENVIRONMENT \
#   --image docker.io/shadowsocks/shadowsocks-libev \
#   --target-port 80 \
#   --ingress 'external' \
#   --query properties.configuration.ingress.fqdn

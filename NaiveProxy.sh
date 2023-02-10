# !!! 记得打开 80，443 端口
# https://www.youtube.com/watch?v=TY5MmBry1yw
yum install wget -y
# 如果是debian系统是apt install wget
wget https://raw.githubusercontent.com/imajeason/nas_tools/main/NaiveProxy/install.sh
mkdir -p /etc/letsencrypt/live/
bash install.sh

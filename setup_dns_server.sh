docker run --name adguardhome \
  --restart always \
  -p 443:443 -p 853:853 -p 3000:3000 -p 53:53/udp -p 53:53/tcp \
  -d adguard/adguardhome:latest

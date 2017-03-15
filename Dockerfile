FROM oddrationale/docker-shadowsocks
COPY shadowsocks_config.json /shadowsocks_config.json

# Configure container to run as an executable
ENTRYPOINT ["/usr/local/bin/ssserver -c /shadowsocks_config.json"]

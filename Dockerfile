FROM oddrationale/docker-shadowsocks

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

COPY shadowsocks_config.json /shadowsocks_config.json

# Configure container to run as an executable
ENTRYPOINT ["/docker-entrypoint.sh"]

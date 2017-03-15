# shadowsocks
#
# VERSION 0.0.3

FROM ubuntu:16.04
MAINTAINER Dariel Dato-on <oddrationale@gmail.com>

RUN apt-get update && \
    apt-get install -y python-pip libsodium18
RUN pip install shadowsocks==2.8.2

COPY shadowsocks_config.json /shadowsocks_config.json

# Configure container to run as an executable
ENTRYPOINT ["/usr/local/bin/ssserver ssserver -c /shadowsocks_config.json"]

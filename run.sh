#!/usr/bi/env bash

docker rm -f ss_mac && echo "ss_mac removed" || echo "no ss_mac container"
docker run -dt --name ss_mac -p 80:80 mritd/shadowsocks -s "-s 0.0.0.0 -p 80 -m aes-256-cfb -k password --fast-open"

docker rm -f ss_ip && echo "ss_ip removed" || echo "no ss_ip container"
docker run -dt --name ss_ip -p 443:443 mritd/shadowsocks -s "-s 0.0.0.0 -p 443 -m aes-256-cfb -k password --fast-open"

docker rm -f ss_pc && echo "ss_pc removed" || echo "no ss_pc container"
docker run -dt --name ss_pc -p 8080:8080 mritd/shadowsocks -s "-s 0.0.0.0 -p 8080 -m aes-256-cfb -k password --fast-open"


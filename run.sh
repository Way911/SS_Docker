#!/usr/bi/env bash

docker rm -f ss_server && echo "ss_server removed" || echo "no ss_server container"

docker build -t ss_server .

docker run -d --name ss_server -p 80:80 -p 443:443 -p 8080:8080 ss_server

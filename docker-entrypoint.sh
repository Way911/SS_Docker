#!/bin/bash
set -e

exec /usr/local/bin/ssserver -c /shadowsocks_config.json "$@"

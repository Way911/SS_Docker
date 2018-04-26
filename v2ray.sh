#!/usr/bi/env bash

docker rm -f ss_mac && echo "ss_mac removed" || echo "no ss_mac container"
docker run -dt --restart always --name ss_mac -p 80:80 mritd/shadowsocks -s "-s 0.0.0.0 -p 80 -m aes-256-cfb -k password --fast-open"

docker rm -f ss_ip && echo "ss_ip removed" || echo "no ss_ip container"
docker run -dt --restart always --name ss_ip -p 443:443 mritd/shadowsocks -s "-s 0.0.0.0 -p 443 -m aes-256-cfb -k password --fast-open"

docker rm -f ss_pc && echo "ss_pc removed" || echo "no ss_pc container"
docker run -dt --restart always --name ss_pc -p 8080:8080 mritd/shadowsocks -s "-s 0.0.0.0 -p 8080 -m aes-256-cfb -k password --fast-open"

#!/bin/bash

red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'

# Root
[[ $(id -u) != 0 ]] && echo -e " 哎呀……请使用 ${red}root ${none}用户运行 ${yellow}~(^_^) ${none}" && exit 1

cmd="apt-get"

sys_bit=$(uname -m)

if [[ $sys_bit == "i386" || $sys_bit == "i686" ]]; then
	v2ray_bit="32"
elif [[ $sys_bit == "x86_64" ]]; then
	v2ray_bit="64"
else
	echo -e " 哈哈……这个 ${red}辣鸡脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}" && exit 1
fi

# 笨笨的检测方法
if [[ -f /usr/bin/apt-get ]] || [[ -f /usr/bin/yum && -f /bin/systemctl ]]; then

	if [[ -f /usr/bin/yum ]]; then

		cmd="yum"

	fi
	if [[ -f /bin/systemctl ]]; then
		systemd=true
	fi

else

	echo -e " 哈哈……这个 ${red}辣鸡脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}" && exit 1

fi

uuid=$(cat /proc/sys/kernel/random/uuid)
old_id="23332333-2333-2333-2333-233boy233boy"
v2ray_server_config="/etc/v2ray/config.json"
v2ray_client_config="/etc/v2ray/233blog_v2ray_config.json"
backup="/etc/v2ray/233blog_v2ray_backup.txt"

transport=(
	TCP
	TCP_HTTP
	WebSocket
	"WebSocket + TLS"
	mKCP
	mKCP_utp
	mKCP_srtp
	mKCP_wechat-video
	TCP_dynamicPort
	TCP_HTTP_dynamicPort
	WebSocket_dynamicPort
	mKCP_dynamicPort
	mKCP_utp_dynamicPort
	mKCP_srtp_dynamicPort
	mKCP_wechat-video_dynamicPort
)

ciphers=(
	aes-128-cfb
	aes-256-cfb
	chacha20
	chacha20-ietf
	aes-128-gcm
	aes-256-gcm
	chacha20-ietf-poly1305
)

v2ray_config() {
	# clear
	echo
	while :; do
		echo -e "请选择 "$yellow"V2Ray"$none" 传输协议 [${magenta}1-${#transport[*]}$none]"
		echo
		for ((i = 1; i <= ${#transport[*]}; i++)); do
			Stream="${transport[$i - 1]}"
			if [[ "$i" -le 9 ]]; then
				# echo
				echo -e "$yellow  $i. $none${Stream}"
			else
				# echo
				echo -e "$yellow $i. $none${Stream}"
			fi
		done
		echo
		echo "备注1: 含有 [dynamicPort] 的即启用动态端口.."
		echo "备注2: [utp | srtp | wechat-video] 分别为 伪装成 [BT下载 | 视频通话 | 微信视频通话]"
		echo
		read -p "$(echo -e "(默认协议: ${cyan}TCP$none)"):" v2ray_transport_opt
		[ -z "$v2ray_transport_opt" ] && v2ray_transport_opt=1
		case $v2ray_transport_opt in
		[1-9] | 1[0-5])
			echo
			echo
			echo -e "$yellow V2Ray 传输协议 = $cyan${transport[$v2ray_transport_opt - 1]}$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		*)
			error
			;;
		esac
	done
	v2ray_port_config
}
v2ray_port_config() {
	if [[ $v2ray_transport_opt -ne 4 && $v2ray_transport_opt -lt 9 ]]; then
		local random=$(shuf -i20001-65535 -n1)
		while :; do
			echo -e "请输入 "$yellow"V2Ray"$none" 端口 ["$magenta"1-65535"$none"]"
			read -p "$(echo -e "(默认端口: ${cyan}${random}$none):")" v2ray_port
			[ -z "$v2ray_port" ] && v2ray_port=$random
			case $v2ray_port in
			[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
				echo
				echo
				echo -e "$yellow V2Ray 端口 = $cyan$v2ray_port$none"
				echo "----------------------------------------------------------------"
				echo
				break
				;;
			*)
				error
				;;
			esac
		done

	elif [[ $v2ray_transport_opt -ge 9 ]]; then

		v2ray_dynamic_port_config

	else

		ws_config

	fi
}

v2ray_dynamic_port_config() {

	echo
	local random=$(shuf -i20001-65535 -n1)
	while :; do
		echo -e "请输入 "$yellow"V2Ray"$none" 端口 ["$magenta"1-65535"$none"]"
		read -p "$(echo -e "(默认端口: ${cyan}${random}$none):")" v2ray_port
		[ -z "$v2ray_port" ] && v2ray_port=$random
		case $v2ray_port in
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			echo
			echo
			echo -e "$yellow V2Ray 端口 = $cyan$v2ray_port$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		*)
			error
			;;
		esac
	done

	v2ray_dynamic_port_start
}

v2ray_dynamic_port_start() {

	while :; do
		echo -e "请输入 "$yellow"V2Ray 动态端口开始 "$none"范围 ["$magenta"1-65535"$none"]"
		read -p "$(echo -e "(默认开始端口: ${cyan}10000$none):")" v2ray_dynamic_port_start_input
		[ -z $v2ray_dynamic_port_start_input ] && v2ray_dynamic_port_start_input=10000
		case $v2ray_dynamic_port_start_input in
		$v2ray_port)
			echo
			echo " 不能和 V2Ray 端口一毛一样...."
			error
			;;
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			echo
			echo
			echo -e "$yellow V2Ray 动态端口开始 = $cyan$v2ray_dynamic_port_start_input$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		*)
			error
			;;
		esac

	done

	if [[ $v2ray_dynamic_port_start_input -lt $v2ray_port ]]; then
		lt_v2ray_port=true
	fi

	v2ray_dynamic_port_end
}
v2ray_dynamic_port_end() {

	while :; do
		echo -e "请输入 "$yellow"V2Ray 动态端口结束 "$none"范围 ["$magenta"1-65535"$none"]"
		read -p "$(echo -e "(默认结束端口: ${cyan}20000$none):")" v2ray_dynamic_port_end_input
		[ -z $v2ray_dynamic_port_end_input ] && v2ray_dynamic_port_end_input=20000
		case $v2ray_dynamic_port_end_input in
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])

			if [[ $v2ray_dynamic_port_end_input -le $v2ray_dynamic_port_start_input ]]; then
				echo
				echo " 不能小于或等于 V2Ray 动态端口开始范围"
				error
			elif [ $lt_v2ray_port ] && [[ ${v2ray_dynamic_port_end_input} -ge $v2ray_port ]]; then
				echo
				echo " V2Ray 动态端口结束范围 不能包括 V2Ray 端口..."
				error
			else
				echo
				echo
				echo -e "$yellow V2Ray 动态端口结束 = $cyan$v2ray_dynamic_port_end_input$none"
				echo "----------------------------------------------------------------"
				echo
				break
			fi
			;;
		*)
			error
			;;
		esac

	done

}

ws_config() {

	echo
	local random=$(shuf -i20001-65535 -n1)
	while :; do
		echo -e "请输入 "$yellow"V2Ray"$none" 端口 ["$magenta"1-65535"$none"]，不能选择 "$magenta"80"$none" 或 "$magenta"443"$none" 端口"
		read -p "$(echo -e "(默认端口: ${cyan}${random}$none):")" v2ray_port
		[ -z "$v2ray_port" ] && v2ray_port=$random
		case $v2ray_port in
		80)
			echo
			echo " ...都说了不能选择 80 端口了咯....."
			error
			;;
		443)
			echo
			echo " ..都说了不能选择 433 端口了咯....."
			error
			;;
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			echo
			echo
			echo -e "$yellow V2Ray 端口 = $cyan$v2ray_port$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		*)
			error
			;;
		esac
	done

	while :; do
		echo
		echo -e "请输入一个 $magenta正确的域名$none，一定一定一定要正确，不！能！出！错！"
		read -p "(例如：233blog.com): " domain
		[ -z "$domain" ] && error && continue
		echo
		echo
		echo -e "$yellow 你的域名 = $cyan$domain$none"
		echo "----------------------------------------------------------------"
		break
	done
	get_ip
	echo
	echo
	echo -e "$yellow 请将 $magenta$domain$none $yellow解析到: $cyan$ip$none"
	echo
	echo -e "$yellow 请将 $magenta$domain$none $yellow解析到: $cyan$ip$none"
	echo
	echo -e "$yellow 请将 $magenta$domain$none $yellow解析到: $cyan$ip$none"
	echo "----------------------------------------------------------------"
	echo

	while :; do

		read -p "$(echo -e "(是否已经正确解析: [${magenta}Y$none]):") " record
		if [[ -z "$record" ]]; then
			error
		else
			if [[ "$record" == [Yy] ]]; then
				echo
				echo
				echo -e "$yellow 域名解析 = ${cyan}我确定已经有解析了$none"
				echo "----------------------------------------------------------------"
				echo
				break
			else
				error
			fi
		fi

	done

	echo -e "

		安装 Caddy 来实现 自动配置 TLS
		
		如果你已经安装 Nginx 或 Caddy

		$yellow并且..自己能搞定配置 TLS$none

		那么就不需要 打开自动配置 TLS
		"
	echo "----------------------------------------------------------------"
	echo

	while :; do

		read -p "$(echo -e "(是否自动配置 TLS: [${magenta}Y/N$none]):") " auto_install_caddy
		if [[ -z "$auto_install_caddy" ]]; then
			error
		else
			if [[ "$auto_install_caddy" == [Yy] ]]; then
				caddy=true
				install_caddy_info="打开"
				echo
				echo
				echo -e "$yellow 自动配置 TLS = $cyan$install_caddy_info$none"
				echo "----------------------------------------------------------------"
				echo
				break
			elif [[ "$auto_install_caddy" == [Nn] ]]; then
				install_caddy_info="关闭"
				echo
				echo
				echo -e "$yellow 自动配置 TLS = $cyan$install_caddy_info$none"
				echo "----------------------------------------------------------------"
				echo
				break
			else
				error
			fi
		fi

	done
	if [[ $caddy ]]; then
		ws_path_config_ask
	fi
}
ws_path_config_ask() {
	echo
	while :; do
		echo -e "是否开启 网站伪装 和 路径分流 [${magenta}Y/N$none]"
		read -p "$(echo -e "(默认: [${cyan}N$none]):")" is_ws_path
		[[ -z $is_ws_path ]] && is_ws_path="n"

		case $is_ws_path in
		Y | y)
			ws_path_config
			break
			;;
		N | n)
			echo
			echo
			echo -e "$yellow 网站伪装 和 路径分流 = $cyan不想配置$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		*)
			error
			;;
		esac
	done
}
ws_path_config() {
	echo
	while :; do
		echo -e "请输入想要 ${magenta}用来分流的路径$none , 例如 /233blog , 那么只需要输入 233blog 即可"
		read -p "$(echo -e "(默认: [${cyan}233blog$none]):")" ws_path
		[[ -z $ws_path ]] && ws_path="233blog"

		case $ws_path in
		*/*)
			echo
			echo -e " 由于这个脚本太辣鸡了..所以不能包含 $red/$none 这个符号.... "
			echo
			error
			;;
		*)
			echo
			echo
			echo -e "$yellow 分流的路径 = ${cyan}/${ws_path}$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		esac
	done
	proxy_site_config
}
proxy_site_config() {
	echo
	while :; do
		echo -e "请输入 ${magenta}一个正确的$none ${cyan}网址$none 用来作为 ${cyan}网站的伪装$none , 例如 https://liyafly.com"
		echo -e "举例...你当前的域名是 $green$domain$none , 伪装的网址的是 https://liyafly.com"
		echo -e "然后打开你的域名时候...显示出来的内容就是来自 https://liyafly.com 的内容"
		echo -e "其实就是一个反代...明白就好..."
		echo -e "如果不能伪装成功...可以使用 v2ray config 修改伪装的网址"
		read -p "$(echo -e "(默认: [${cyan}https://liyafly.com$none]):")" proxy_site
		[[ -z $proxy_site ]] && proxy_site="https://liyafly.com"

		case $proxy_site in
		*)
			echo
			echo
			echo -e "$yellow 伪装的网址 = ${cyan}${proxy_site}$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		esac
	done
}

blocked_hosts() {
	echo
	while :; do
		echo -e "是否开启广告拦截 [${magenta}Y/N$none]"
		read -p "$(echo -e "(默认 [${cyan}N$none]):")" blocked_ad
		[[ -z $blocked_ad ]] && blocked_ad="n"

		case $blocked_ad in
		Y | y)
			blocked_ad_info="开启"
			is_blocked_ad=true
			echo
			echo
			echo -e "$yellow 广告拦截 = $cyan开启$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		N | n)
			blocked_ad_info="关闭"
			echo
			echo
			echo -e "$yellow 广告拦截 = $cyan关闭$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		*)
			error
			;;
		esac
	done
}
shadowsocks_config() {

	echo

	while :; do
		echo -e "是否配置 ${yellow}Shadowsocks${none} [${magenta}Y/N$none]"
		read -p "$(echo -e "(默认 [${cyan}N$none]):") " install_shadowsocks
		[[ -z "$install_shadowsocks" ]] && install_shadowsocks="n"
		if [[ "$install_shadowsocks" == [Yy] ]]; then
			echo
			shadowsocks=true
			shadowsocks_port_config
			break
		elif [[ "$install_shadowsocks" == [Nn] ]]; then
			break
		else
			error
		fi

	done

}

shadowsocks_port_config() {
	local random=$(shuf -i20001-65535 -n1)
	while :; do
		echo -e "请输入 "$yellow"Shadowsocks"$none" 端口 ["$magenta"1-65535"$none"]，不能和 "$yellow"V2Ray"$none" 端口相同"
		read -p "$(echo -e "(默认端口: ${cyan}${random}$none):") " ssport
		[ -z "$ssport" ] && ssport=$random
		case $ssport in
		$v2ray_port)
			echo
			echo " 不能和 V2Ray 端口一毛一样...."
			error
			;;
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			if [[ $v2ray_transport_opt == "4" && $ssport == "80" ]] || [[ $v2ray_transport_opt == "4" && $ssport == "443" ]]; then
				echo
				echo -e "由于你选择了 "$green"WebSocket + TLS"$none" 传输协议."
				echo
				echo -e "所以不能选择 "$magenta"80"$none" 或 "$magenta"443"$none" 端口"
				error
			elif [[ $v2ray_dynamic_port_start_input == $ssport || $v2ray_dynamic_port_end_input == $ssport ]]; then
				local multi_port="${v2ray_dynamic_port_start_input} - ${v2ray_dynamic_port_end_input}"
				echo
				echo " 抱歉，此端口和 V2Ray 动态端口 冲突，当前 V2Ray 动态端口范围为：$multi_port"
				error
			elif [[ $v2ray_dynamic_port_start_input -lt $ssport && $ssport -le $v2ray_dynamic_port_end_input ]]; then
				local multi_port="${v2ray_dynamic_port_start_input} - ${v2ray_dynamic_port_end_input}"
				echo
				echo " 抱歉，此端口和 V2Ray 动态端口 冲突，当前 V2Ray 动态端口范围为：$multi_port"
				error
			else
				echo
				echo
				echo -e "$yellow Shadowsocks 端口 = $cyan$ssport$none"
				echo "----------------------------------------------------------------"
				echo
				break
			fi
			;;
		*)
			error
			;;
		esac

	done

	shadowsocks_password_config
}
shadowsocks_password_config() {

	while :; do
		echo -e "请输入 "$yellow"Shadowsocks"$none" 密码"
		read -p "$(echo -e "(默认密码: ${cyan}233blog.com$none)"): " sspass
		[ -z "$sspass" ] && sspass="233blog.com"
		case $sspass in
		*/*)
			echo
			echo -e " 由于这个脚本太辣鸡了..所以密码不能包含 $red/$none 这个符号.... "
			echo
			error
			;;
		*)
			echo
			echo
			echo -e "$yellow Shadowsocks 密码 = $cyan$sspass$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		esac

	done

	shadowsocks_ciphers_config
}
shadowsocks_ciphers_config() {

	while :; do
		echo -e "请选择 "$yellow"Shadowsocks"$none" 加密协议 [${magenta}1-${#ciphers[*]}$none]"
		for ((i = 1; i <= ${#ciphers[*]}; i++)); do
			ciphers_show="${ciphers[$i - 1]}"
			echo
			echo -e "$yellow $i. $none${ciphers_show}"
		done
		echo
		read -p "$(echo -e "(默认加密协议: ${cyan}${ciphers[6]}$none)"):" ssciphers_opt
		[ -z "$ssciphers_opt" ] && ssciphers_opt=7
		case $ssciphers_opt in
		[1-7])
			ssciphers=${ciphers[$ssciphers_opt - 1]}
			echo
			echo
			echo -e "$yellow Shadowsocks 加密协议 = $cyan${ssciphers}$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		*)
			error
			;;
		esac

	done
	pause
}

install_info() {
	clear
	echo
	echo " ....准备安装了咯..看看有毛有配置正确了..."
	echo
	echo "---------- 安装信息 -------------"
	echo
	echo -e "$yellow V2Ray 传输协议 = $cyan${transport[$v2ray_transport_opt - 1]}$none"

	if [[ $v2ray_transport_opt == "4" ]]; then
		echo
		echo -e "$yellow V2Ray 端口 = $cyan$v2ray_port$none"
		echo
		echo -e "$yellow 你的域名 = $cyan$domain$none"
		echo
		echo -e "$yellow 域名解析 = ${cyan}我确定已经有解析了$none"
		echo
		echo -e "$yellow 自动配置 TLS = $cyan$install_caddy_info$none"

		if [[ $is_blocked_ad ]]; then
			echo
			echo -e "$yellow 广告拦截 = $cyan$blocked_ad_info$none"
		fi
		if [[ $ws_path ]]; then
			echo
			echo -e "$yellow 路径分流 = ${cyan}/${ws_path}$none"
		fi
	elif [[ $v2ray_transport_opt -ge 9 ]]; then
		echo
		echo -e "$yellow V2Ray 端口 = $cyan$v2ray_port$none"
		echo
		echo -e "$yellow V2Ray 动态端口范围 = $cyan${v2ray_dynamic_port_start_input} - ${v2ray_dynamic_port_end_input}$none"

		if [[ $is_blocked_ad ]]; then
			echo
			echo -e "$yellow 广告拦截 = $cyan$blocked_ad_info$none"
		fi
	else
		echo
		echo -e "$yellow V2Ray 端口 = $cyan$v2ray_port$none"

		if [[ $is_blocked_ad ]]; then
			echo
			echo -e "$yellow 广告拦截 = $cyan$blocked_ad_info$none"
		fi
	fi
	if [ $shadowsocks ]; then
		echo
		echo -e "$yellow Shadowsocks 端口 = $cyan$ssport$none"
		echo
		echo -e "$yellow Shadowsocks 密码 = $cyan$sspass$none"
		echo
		echo -e "$yellow Shadowsocks 加密协议 = $cyan${ssciphers}$none"
	else
		echo
		echo -e "$yellow 是否配置 Shadowsocks = ${cyan}未配置${none}"
	fi
	echo
	echo "---------- END -------------"
	echo
	pause
	echo
}

domain_check() {
	# if [[ $cmd == "yum" ]]; then
	# 	yum install bind-utils -y
	# else
	# 	$cmd install dnsutils -y
	# fi
	# test_domain=$(dig $domain +short)
	test_domain=$(ping $domain -c 1 | grep -oP -m1 "(\d+\.){3}\d+")
	if [[ $test_domain != $ip ]]; then
		echo
		echo -e "$red 检测域名解析错误....$none"
		echo
		echo -e " 你的域名: $yellow$domain$none 未解析到: $cyan$ip$none"
		echo
		echo -e " 你的域名当前解析到: $cyan$test_domain$none"
		echo
		echo "备注...如果你的域名是使用 Cloudflare 解析的话..在 Status 那里点一下那图标..让它变灰"
		echo
		exit 1
	fi
}

install_caddy() {
	local caddy_tmp="/tmp/install_caddy/"
	local caddy_tmp_file="/tmp/install_caddy/caddy.tar.gz"
	if [[ $sys_bit == "i386" || $sys_bit == "i686" ]]; then
		local caddy_download_link="https://caddyserver.com/download/linux/386?license=personal"
	elif [[ $sys_bit == "x86_64" ]]; then
		local caddy_download_link="https://caddyserver.com/download/linux/amd64?license=personal"
	else
		echo -e "$red 自动安装 Caddy 失败！不支持你的系统。$none" && exit 1
	fi

	mkdir -p $caddy_tmp

	if ! wget --no-check-certificate -O "$caddy_tmp_file" $caddy_download_link; then
		echo -e "$red 下载 Caddy 失败！$none" && exit 1
	fi

	tar zxf $caddy_tmp_file -C $caddy_tmp
	cp -f ${caddy_tmp}caddy /usr/local/bin/

	if [[ ! -f /usr/local/bin/caddy ]]; then
		echo -e "$red 安装 Caddy 出错！" && exit 1
	fi

	setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/caddy

	if [[ $systemd ]]; then
		cp -f ${caddy_tmp}init/linux-systemd/caddy.service /lib/systemd/system/
		# sed -i "s/www-data/root/g" /lib/systemd/system/caddy.service
		systemctl enable caddy
	else
		cp -f ${caddy_tmp}init/linux-sysvinit/caddy /etc/init.d/caddy
		# sed -i "s/www-data/root/g" /etc/init.d/caddy
		chmod +x /etc/init.d/caddy
		update-rc.d -f caddy defaults
	fi

	mkdir -p /etc/ssl/caddy

	if [ -z "$(grep www-data /etc/passwd)" ]; then
		useradd -M -s /usr/sbin/nologin www-data
	fi
	chown -R www-data.www-data /etc/ssl/caddy

	mkdir -p /etc/caddy/
	rm -rf $caddy_tmp
	caddy_config

}
caddy_config() {
	local email=$(shuf -i1-10000000000 -n1)
	if [[ $ws_path ]]; then
		cat >/etc/caddy/Caddyfile <<-EOF
$domain {
    tls ${email}@gmail.com
    gzip
    proxy / $proxy_site {
        without /${ws_path}
    }
    proxy /${ws_path} 127.0.0.1:${v2ray_port} {
        without /${ws_path}
        websocket
    }
}
		EOF
	else
		cat >/etc/caddy/Caddyfile <<-EOF
$domain {
    tls ${email}@gmail.com
	proxy / 127.0.0.1:${v2ray_port} {
		websocket
	}
}
		EOF
	fi

	# systemctl restart caddy
	do_service restart caddy
}

install_v2ray() {
	$cmd update -y
	# if [[ $cmd == "apt-get" ]]; then
	# 	$cmd install -y lrzsz git zip unzip curl wget qrencode dnsutils
	# else
	# 	$cmd install -y lrzsz git zip unzip curl wget qrencode bind-utils iptables-services
	# fi
	if [[ $cmd == "apt-get" ]]; then
		$cmd install -y lrzsz git zip unzip curl wget qrencode libcap2-bin
	else
		$cmd install -y lrzsz git zip unzip curl wget qrencode libcap iptables-services
	fi
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

	if [[ $local_install ]]; then
		if [[ ! -d $(pwd)/config ]]; then
			echo
			echo -e "$red 哎呀呀...安装失败了咯...$none"
			echo
			echo -e " 请确保你有完整的上传 233blog.com V2Ray 一键安装脚本 & 管理脚本到当前 ${green}$(pwd) $none目录下"
			echo
			exit 1
		fi
		mkdir -p /etc/v2ray/233boy/v2ray
		cp -rf $(pwd)/* /etc/v2ray/233boy/v2ray
	else
		git clone https://github.com/233boy/v2ray /etc/v2ray/233boy/v2ray
	fi

	[ -d /tmp/v2ray ] && rm -rf /tmp/v2ray
	mkdir -p /tmp/v2ray

	v2ray_tmp_file="/tmp/v2ray/v2ray.zip"
	v2ray_ver="$(curl -s https://api.github.com/repos/v2ray/v2ray-core/releases/latest | grep 'tag_name' | cut -d\" -f4)"
	v2ray_download_link="https://github.com/v2ray/v2ray-core/releases/download/$v2ray_ver/v2ray-linux-${v2ray_bit}.zip"

	if ! wget --no-check-certificate -O "$v2ray_tmp_file" $v2ray_download_link; then
		echo -e "
        $red 下载 V2Ray 失败啦..可能是你的小鸡鸡的网络太辣鸡了...重新安装也许能解决$none
        " && exit 1
	fi

	unzip $v2ray_tmp_file -d "/tmp/v2ray/"
	mkdir -p /usr/bin/v2ray
	cp -f "/tmp/v2ray/v2ray-${v2ray_ver}-linux-${v2ray_bit}/v2ray" "/usr/bin/v2ray/v2ray"
	chmod +x "/usr/bin/v2ray/v2ray"
	cp -f "/tmp/v2ray/v2ray-${v2ray_ver}-linux-${v2ray_bit}/v2ctl" "/usr/bin/v2ray/v2ctl"
	chmod +x "/usr/bin/v2ray/v2ctl"

	if [[ $systemd ]]; then
		cp -f "/tmp/v2ray/v2ray-${v2ray_ver}-linux-${v2ray_bit}/systemd/v2ray.service" "/lib/systemd/system/"
		systemctl enable v2ray
	else
		apt-get install -y daemon
		cp "/tmp/v2ray/v2ray-${v2ray_ver}-linux-${v2ray_bit}/systemv/v2ray" "/etc/init.d/v2ray"
		chmod +x "/etc/init.d/v2ray"
		update-rc.d -f v2ray defaults
	fi

	mkdir -p /var/log/v2ray
	mkdir -p /etc/v2ray

	rm -rf /tmp/v2ray

	if [ $shadowsocks ]; then
		if [[ $is_blocked_ad ]]; then
			case $v2ray_transport_opt in
			1)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/tcp_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/tcp.json"
				;;
			2)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/http_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/http.json"
				;;
			3)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/ws_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws.json"
				;;
			4)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/ws_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws_tls.json"
				;;
			5 | 6 | 7 | 8)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/kcp_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/kcp.json"
				;;
			9)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/tcp_ss_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/tcp.json"
				;;
			10)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/http_ss_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/http.json"
				;;
			11)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/ws_ss_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws.json"
				;;
			12 | 13 | 14 | 15)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/kcp_ss_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/kcp.json"
				;;
			esac
		else
			case $v2ray_transport_opt in
			1)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/tcp_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/tcp.json"
				;;
			2)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/http_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/http.json"
				;;
			3)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/ws_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws.json"
				;;
			4)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/ws_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws_tls.json"
				;;
			5 | 6 | 7 | 8)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/kcp_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/kcp.json"
				;;
			9)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/tcp_ss_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/tcp.json"
				;;
			10)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/http_ss_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/http.json"
				;;
			11)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/ws_ss_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws.json"
				;;
			12 | 13 | 14 | 15)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/kcp_ss_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/kcp.json"
				;;
			esac
		fi
	else
		if [[ $is_blocked_ad ]]; then
			case $v2ray_transport_opt in
			1)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/tcp.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/tcp.json"
				;;
			2)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/http.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/http.json"
				;;
			3)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/ws.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws.json"
				;;
			4)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/ws.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws_tls.json"
				;;
			5 | 6 | 7 | 8)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/kcp.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/kcp.json"
				;;
			9)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/sblocked_hosts/erver/tcp_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/tcp.json"
				;;
			10)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/http_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/http.json"
				;;
			11)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/ws_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws.json"
				;;
			12 | 13 | 14 | 15)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/kcp_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/kcp.json"
				;;
			esac
		else
			case $v2ray_transport_opt in
			1)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/tcp.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/tcp.json"
				;;
			2)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/http.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/http.json"
				;;
			3)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/ws.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws.json"
				;;
			4)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/ws.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws_tls.json"
				;;
			5 | 6 | 7 | 8)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/kcp.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/kcp.json"
				;;
			9)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/tcp_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/tcp.json"
				;;
			10)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/http_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/http.json"
				;;
			11)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/ws_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws.json"
				;;
			12 | 13 | 14 | 15)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/kcp_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/kcp.json"
				;;
			esac
		fi

	fi

}

open_port() {
	if [[ $1 != "multiport" ]]; then

		iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $1 -j ACCEPT
		iptables -I INPUT -m state --state NEW -m udp -p udp --dport $1 -j ACCEPT
		ip6tables -I INPUT -m state --state NEW -m tcp -p tcp --dport $1 -j ACCEPT
		ip6tables -I INPUT -m state --state NEW -m udp -p udp --dport $1 -j ACCEPT

		# firewall-cmd --permanent --zone=public --add-port=$1/tcp
		# firewall-cmd --permanent --zone=public --add-port=$1/udp
		# firewall-cmd --reload

	else

		local multiport="${v2ray_dynamic_port_start_input}:${v2ray_dynamic_port_end_input}"
		iptables -I INPUT -p tcp --match multiport --dports $multiport -j ACCEPT
		iptables -I INPUT -p udp --match multiport --dports $multiport -j ACCEPT
		ip6tables -I INPUT -p tcp --match multiport --dports $multiport -j ACCEPT
		ip6tables -I INPUT -p udp --match multiport --dports $multiport -j ACCEPT

		# local multi_port="${v2ray_dynamic_port_start_input}-${v2ray_dynamic_port_end_input}"
		# firewall-cmd --permanent --zone=public --add-port=$multi_port/tcp
		# firewall-cmd --permanent --zone=public --add-port=$multi_port/udp
		# firewall-cmd --reload

	fi
	if [[ $cmd == "apt-get" ]]; then
		iptables-save >/etc/iptables.rules.v4
		ip6tables-save >/etc/iptables.rules.v6
	else
		service iptables save >/dev/null 2>&1
		service ip6tables save >/dev/null 2>&1
	fi
}
del_port() {
	if [[ $1 != "multiport" ]]; then
		# if [[ $cmd == "apt-get" ]]; then
		iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport $1 -j ACCEPT
		iptables -D INPUT -m state --state NEW -m udp -p udp --dport $1 -j ACCEPT
		ip6tables -D INPUT -m state --state NEW -m tcp -p tcp --dport $1 -j ACCEPT
		ip6tables -D INPUT -m state --state NEW -m udp -p udp --dport $1 -j ACCEPT
		# else
		# 	firewall-cmd --permanent --zone=public --remove-port=$1/tcp
		# 	firewall-cmd --permanent --zone=public --remove-port=$1/udp
		# fi
	else
		# if [[ $cmd == "apt-get" ]]; then
		local port_start=$(sed -n '23p' $backup)
		local port_end=$(sed -n '25p' $backup)
		local ports="${port_start}:${port_end}"
		iptables -D INPUT -p tcp --match multiport --dports $ports -j ACCEPT
		iptables -D INPUT -p udp --match multiport --dports $ports -j ACCEPT
		ip6tables -D INPUT -p tcp --match multiport --dports $ports -j ACCEPT
		ip6tables -D INPUT -p udp --match multiport --dports $ports -j ACCEPT
		# else
		# 	local port_start=$(sed -n '23p' $backup)
		# 	local port_end=$(sed -n '25p' $backup)
		# 	local ports="${port_start}-${port_end}"
		# 	firewall-cmd --permanent --zone=public --remove-port=$ports/tcp
		# 	firewall-cmd --permanent --zone=public --remove-port=$ports/udp
		# fi
	fi

	if [[ $cmd == "apt-get" ]]; then
		iptables-save >/etc/iptables.rules.v4
		ip6tables-save >/etc/iptables.rules.v6
	else
		service iptables save >/dev/null 2>&1
		service ip6tables save >/dev/null 2>&1
	fi

}

config() {
	cp -f $v2ray_server_config_file $v2ray_server_config
	cp -f $v2ray_client_config_file $v2ray_client_config
	cp -f /etc/v2ray/233boy/v2ray/config/backup.txt $backup
	cp -f /etc/v2ray/233boy/v2ray/v2ray.sh /usr/local/bin/v2ray
	chmod +x /usr/local/bin/v2ray

	local multi_port="${v2ray_dynamic_port_start_input}-${v2ray_dynamic_port_end_input}"
	if [ $shadowsocks ]; then
		case $v2ray_transport_opt in
		1)
			sed -i "28s/6666/$ssport/; 30s/chacha20-ietf/$ssciphers/; 31s/233blog.com/$sspass/" $v2ray_server_config
			;;
		2)
			sed -i "50s/6666/$ssport/; 52s/chacha20-ietf/$ssciphers/; 53s/233blog.com/$sspass/" $v2ray_server_config
			;;
		3 | 4)
			sed -i "31s/6666/$ssport/; 33s/chacha20-ietf/$ssciphers/; 34s/233blog.com/$sspass/" $v2ray_server_config
			;;
		5 | 6 | 7 | 8)
			sed -i "43s/6666/$ssport/; 45s/chacha20-ietf/$ssciphers/; 46s/233blog.com/$sspass/" $v2ray_server_config
			;;
		9)
			sed -i "31s/6666/$ssport/; 33s/chacha20-ietf/$ssciphers/; 34s/233blog.com/$sspass/; 42s/10000-20000/$multi_port/" $v2ray_server_config
			;;
		10)
			sed -i "67s/6666/$ssport/; 69s/chacha20-ietf/$ssciphers/; 70s/233blog.com/$sspass/; 78s/10000-20000/$multi_port/" $v2ray_server_config
			;;
		*)

			sed -i "34s/6666/$ssport/; 36s/chacha20-ietf/$ssciphers/; 37s/233blog.com/$sspass/; 45s/10000-20000/$multi_port/" $v2ray_server_config
			;;
		esac

		case $v2ray_transport_opt in
		6)
			sed -i "31s/none/utp/" $v2ray_server_config
			sed -i "44s/none/utp/" $v2ray_client_config
			;;
		7)
			sed -i "31s/none/srtp/" $v2ray_server_config
			sed -i "44s/none/srtp/" $v2ray_client_config
			;;
		8)
			sed -i "31s/none/wechat-video/" $v2ray_server_config
			sed -i "44s/none/wechat-video/" $v2ray_client_config
			;;
		13)
			sed -i "74s/none/utp/" $v2ray_server_config
			sed -i "44s/none/utp/" $v2ray_client_config
			;;
		14)
			sed -i "74s/none/srtp/" $v2ray_server_config
			sed -i "44s/none/srtp/" $v2ray_client_config
			;;
		15)
			sed -i "74s/none/wechat-video/" $v2ray_server_config
			sed -i "44s/none/wechat-video/" $v2ray_client_config
			;;
		esac

	else
		case $v2ray_transport_opt in
		9)
			sed -i "31s/10000-20000/$multi_port/" $v2ray_server_config
			;;
		10)
			sed -i "67s/10000-20000/$multi_port/" $v2ray_server_config
			;;
		11 | 12 | 13 | 14 | 15)
			sed -i "34s/10000-20000/$multi_port/" $v2ray_server_config
			;;
		esac

		case $v2ray_transport_opt in
		6)
			sed -i "31s/none/utp/" $v2ray_server_config
			sed -i "44s/none/utp/" $v2ray_client_config
			;;
		7)
			sed -i "31s/none/srtp/" $v2ray_server_config
			sed -i "44s/none/srtp/" $v2ray_client_config
			;;
		8)
			sed -i "31s/none/wechat-video/" $v2ray_server_config
			sed -i "44s/none/wechat-video/" $v2ray_client_config
			;;
		13)
			sed -i "63s/none/utp/" $v2ray_server_config
			sed -i "44s/none/utp/" $v2ray_client_config
			;;
		14)
			sed -i "63s/none/srtp/" $v2ray_server_config
			sed -i "44s/none/srtp/" $v2ray_client_config
			;;
		15)
			sed -i "63s/none/wechat-video/" $v2ray_server_config
			sed -i "44s/none/wechat-video/" $v2ray_client_config
			;;
		esac

	fi

	sed -i "8s/2333/$v2ray_port/; 14s/$old_id/$uuid/" $v2ray_server_config

	if [[ $v2ray_transport_opt -eq 4 ]]; then
		sed -i "s/233blog.com/$domain/; 22s/2333/443/; 25s/$old_id/$uuid/" $v2ray_client_config
		if [[ $ws_path ]]; then
			sed -i "41s/233blog/$ws_path/" $v2ray_client_config
		else
			sed -i "41s/233blog//" $v2ray_client_config
		fi
	else
		sed -i "s/233blog.com/$ip/; 22s/2333/$v2ray_port/; 25s/$old_id/$uuid/" $v2ray_client_config
	fi

	zip -q -r -j --password "233blog.com" /etc/v2ray/233blog_v2ray.zip $v2ray_client_config

	if [[ $cmd == "apt-get" ]]; then
		cat >/etc/network/if-pre-up.d/iptables <<-EOF
#!/bin/sh
/sbin/iptables-restore < /etc/iptables.rules.v4
/sbin/ip6tables-restore < /etc/iptables.rules.v6
	EOF
		chmod +x /etc/network/if-pre-up.d/iptables
	else
		[ $(pgrep "firewall") ] && systemctl stop firewalld
		systemctl mask firewalld
		systemctl disable firewalld
		systemctl enable iptables
		systemctl enable ip6tables
		systemctl start iptables
		systemctl start ip6tables
	fi

	[ $shadowsocks ] && open_port $ssport
	if [[ $v2ray_transport_opt == "4" ]]; then
		open_port "80"
		open_port "443"
		open_port $v2ray_port
	elif [[ $v2ray_transport_opt -ge 9 ]]; then
		open_port $v2ray_port
		open_port "multiport"
	else
		open_port $v2ray_port
	fi
	# systemctl restart v2ray
	do_service restart v2ray
	backup_config

}

backup_config() {
	sed -i "17s/1/$v2ray_transport_opt/; 19s/2333/$v2ray_port/; 21s/$old_id/$uuid/;" $backup
	if [ $v2ray_transport_opt -ge 9 ]; then
		sed -i "23s/10000/$v2ray_dynamic_port_start_input/; 25s/20000/$v2ray_dynamic_port_end_input/" $backup
	fi
	if [ $shadowsocks ]; then
		sed -i "31s/false/true/; 33s/6666/$ssport/; 35s/233blog.com/$sspass/; 37s/chacha20-ietf/$ssciphers/" $backup
	fi
	[ $v2ray_transport_opt == "4" ] && sed -i "27s/233blog.com/$domain/" $backup
	[ $caddy ] && sed -i "29s/false/true/" $backup
	[ $is_blocked_ad ] && sed -i "39s/false/true/" $backup
	if [[ $ws_path ]]; then
		sed -i "41s/false/true/; 43s/233blog/$ws_path/; $ d" $backup
		echo "$proxy_site" >>$backup
	fi

}

try_enable_bbr() {
	if [[ $(uname -r | cut -b 1) -eq 4 ]]; then
		case $(uname -r | cut -b 3-4) in
		9. | [1-9][0-9])
			sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
			sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
			echo "net.ipv4.tcp_congestion_control = bbr" >>/etc/sysctl.conf
			echo "net.core.default_qdisc = fq" >>/etc/sysctl.conf
			sysctl -p >/dev/null 2>&1
			;;
		esac
	fi
}

get_ip() {
	ip=$(curl -s ipinfo.io/ip)
}

error() {

	echo -e "\n$red 输入错误！$none\n"

}

pause() {

	read -rsp "$(echo -e "按$green Enter 回车键 $none继续....或按$red Ctrl + C $none取消.")" -d $'\n'
	echo
}
do_service() {
	if [[ $systemd ]]; then
		systemctl $1 $2
	else
		service $2 $1
	fi
}
show_config_info() {
	local header="none"
	if [[ $ws_path ]]; then
		local host="/$ws_path"
	else
		local host=""
	fi

	case $v2ray_transport_opt in
	1 | 9)
		local net="tcp"
		local network="tcp"
		local obfs="none"
		;;
	2 | 10)
		local net="tcp"
		local network="tcp"
		local header="http"
		local host="www.baidu.com"
		local obfs="http"
		;;
	3 | 4 | 11)
		local net="ws"
		local network="ws (WebSocket)"
		local obfs="websocket"
		;;
	5 | 12)
		local net="kcp"
		local network="kcp"
		;;
	6 | 13)
		local net="kcp"
		local network="kcp"
		local header="utp"
		;;
	7 | 14)
		local net="kcp"
		local network="kcp"
		local header="srtp"
		;;
	8 | 15)
		local net="kcp"
		local network="kcp"
		local header="wechat-video"
		;;
	esac
	if [[ $v2ray_transport_opt == "4" ]]; then
		cat >/etc/v2ray/vmess_qr.json <<-EOF
		{
			"ps": "233blog_v2ray_${domain}",
			"add": "${domain}",
			"port": "443",
			"id": "${uuid}",
			"aid": "233",
			"net": "${net}",
			"type": "none",
			"host": "${host}",
			"tls": "tls"
		}
		EOF
	else
		cat >/etc/v2ray/vmess_qr.json <<-EOF
		{
			"ps": "233blog_v2ray_${ip}",
			"add": "${ip}",
			"port": "${v2ray_port}",
			"id": "${uuid}",
			"aid": "233",
			"net": "${net}",
			"type": "${header}",
			"host": "${host}",
			"tls": ""
		}
		EOF
	fi
	if [[ $obfs ]]; then
		if [[ $domain ]]; then
			ip_or_domain=$domain
		else
			ip_or_domain=$ip
		fi
		local shadowray_qr="vmess://$(echo -n "aes-128-cfb:${uuid}@${ip_or_domain}:${v2ray_port}" | base64)?remarks=233blog_v2ray_${ip_or_domain}&obfs=${obfs}"
		echo "${shadowray_qr}" >/etc/v2ray/shadowray_qr.txt
		sed -i 'N;s/\n//' /etc/v2ray/shadowray_qr.txt
	fi
	clear
	echo
	echo "---------- V2Ray 安装完成 -------------"
	echo
	echo -e " $yellow输入 ${cyan}v2ray${none} $yellow即可管理 V2Ray${none}"
	echo
	echo -e " ${yellow}V2Ray 客户端使用教程: https://233blog.com/post/20/$none"
	echo
	if [[ $v2ray_transport_opt == "4" && ! $caddy ]]; then
		echo -e " $red警告！$none$yellow请自行配置 TLS...教程: https://233blog.com/post/19/$none"
		echo
	fi
	echo "---------- V2Ray 配置信息 -------------"
	if [[ $v2ray_transport_opt == "4" ]]; then
		echo
		echo -e "$yellow 地址 (Address) = $cyan${domain}$none"
		echo
		echo -e "$yellow 端口 (Port) = ${cyan}443${none}"
		echo
		echo -e "$yellow 用户ID (User ID / UUID) = $cyan${uuid}$none"
		echo
		echo -e "$yellow 额外ID (Alter Id) = ${cyan}233${none}"
		echo
		echo -e "$yellow 传输协议 (Network) = ${cyan}${network}$none"
		echo
		echo -e "$yellow 伪装类型 (header type) = ${cyan}${header}$none"
		echo
		if [[ $ws_path ]]; then
			echo -e "$yellow WebSocket 路径 (WS path) = ${cyan}/${ws_path}$none"
			echo
		fi
		echo -e "$yellow TLS (Enable TLS) = ${cyan}打开$none"
		echo
		echo -e " 请将 Obfs 设置为 $obfs ...并忽略 传输协议... (如果你使用 Pepi / ShadowRay) "
		echo

	else
		echo
		echo -e "$yellow 地址 (Address) = $cyan${ip}$none"
		echo
		echo -e "$yellow 端口 (Port) = $cyan$v2ray_port$none"
		echo
		echo -e "$yellow 用户ID (User ID / UUID) = $cyan${uuid}$none"
		echo
		echo -e "$yellow 额外ID (Alter Id) = ${cyan}233${none}"
		echo
		echo -e "$yellow 传输协议 (Network) = ${cyan}${net}$none"
		echo
		echo -e "$yellow 伪装类型 (header type) = ${cyan}${header}$none"
		echo
		if [[ $obfs ]]; then
			echo -e " 请将 Obfs 设置为 $obfs ...并忽略 传输协议... (如果你使用 Pepi / ShadowRay) "
			echo
		else
			echo -e " 帅帅的提示...此 V2Ray 配置不支持 Pepi / ShadowRay"
			echo
		fi
	fi
	if [[ $v2ray_transport_opt -ge 9 && $is_blocked_ad ]]; then
		echo " 备注: 动态端口已启用...广告拦截已开启..."
		echo
	elif [[ $v2ray_transport_opt -ge 9 ]]; then
		echo " 备注: 动态端口已启用..."
		echo
	elif [[ $is_blocked_ad ]]; then
		echo " 备注: 广告拦截已开启.."
		echo
	fi
	if [ $shadowsocks ]; then
		local ss="ss://$(echo -n "${ssciphers}:${sspass}@${ip}:${ssport}" | base64)#233blog_ss_${ip}"
		echo
		echo "---------- Shadowsocks 配置信息 -------------"
		echo
		echo -e "$yellow 服务器地址 = $cyan${ip}$none"
		echo
		echo -e "$yellow 服务器端口 = $cyan$ssport$none"
		echo
		echo -e "$yellow 密码 = $cyan$sspass$none"
		echo
		echo -e "$yellow 加密协议 = $cyan${ssciphers}$none"
		echo
		echo -e "$yellow SS 链接 = ${cyan}$ss$none"
		echo
		echo -e " 备注:$red Shadowsocks Win 4.0.6 $none客户端可能无法识别该 SS 链接"
		echo
	fi

}
create_qr_link_ask() {
	if [[ $shadowsocks ]]; then
		echo
		while :; do
			echo -e "是否需要生成$yellow V2Ray 和 Shadowsocks $none配置信息二维码链接 [${magenta}Y/N$none]"
			read -p "$(echo -e "默认 [${magenta}N$none]:")" y_n
			[ -z $y_n ] && y_n="n"
			if [[ $y_n == [Yy] ]]; then
				get_qr_link 1
				break
			elif [[ $y_n == [Nn] ]]; then
				rm -rf /etc/v2ray/vmess_qr.json
				rm -rf /etc/v2ray/shadowray_qr.txt
				break
			else
				error
			fi
		done
	else
		echo
		while :; do
			echo -e "是否需要生成$yellow V2Ray 配置信息 $none二维码链接 [${magenta}Y/N$none]"
			read -p "$(echo -e "默认 [${magenta}N$none]:")" y_n
			[ -z $y_n ] && y_n="n"
			if [[ $y_n == [Yy] ]]; then
				get_qr_link
				break
			elif [[ $y_n == [Nn] ]]; then
				rm -rf /etc/v2ray/vmess_qr.json
				rm -rf /etc/v2ray/shadowray_qr.txt
				break
			else
				error
			fi
		done
	fi
}
get_qr_link() {

	echo
	echo -e "$green 正在生成链接.... 稍等片刻即可....$none"
	echo

	case $v2ray_transport_opt in
	[1-4] | 9 | 10 | 11)
		local ios_qr=true
		local random3=$(echo $RANDOM-$RANDOM-$RANDOM | base64)
		cat /etc/v2ray/shadowray_qr.txt | qrencode -s 50 -o /tmp/233blog_shadowray_qr.png
		local link3=$(curl -s --upload-file /tmp/233blog_shadowray_qr.png "https://transfer.sh/${random3}_233blog_v2ray.png")
		;;
	esac

	if [[ $1 ]]; then
		local vmess="vmess://$(cat /etc/v2ray/vmess_qr.json | base64)"
		echo $vmess >/etc/v2ray/vmess.txt
		cat /etc/v2ray/vmess.txt | qrencode -s 50 -o /tmp/233blog_v2ray.png
		local ss="ss://$(echo -n "${ssciphers}:${sspass}@${ip}:${ssport}" | base64)#233blog_ss_${ip}"
		echo "${ss}" >/tmp/233blog_shadowsocks.txt
		cat /tmp/233blog_shadowsocks.txt | qrencode -s 50 -o /tmp/233blog_shadowsocks.png
		local random1=$(echo $RANDOM-$RANDOM-$RANDOM | base64)
		local random2=$(echo $RANDOM-$RANDOM-$RANDOM | base64)
		local link1=$(curl -s --upload-file /tmp/233blog_v2ray.png "https://transfer.sh/${random1}_233blog_v2ray.png")
		local link2=$(curl -s --upload-file /tmp/233blog_shadowsocks.png "https://transfer.sh/${random2}_233blog_shadowsocks.png")
		if [[ $link1 && $link2 ]]; then
			echo
			echo "---------- V2Ray 二维码链接 -------------"
			echo
			echo -e "$yellow 适用于 V2RayNG / Kitsunebi = $cyan${link1}$none"
			echo
			if [[ $ios_qr && $link3 ]]; then
				echo -e "$yellow 适用于 Pepi / ShadowRay = $cyan${link3}$none"
				echo
				echo " 请在 Pepi / ShadowRay 配置界面将 Alter Id 设置为 233 (如果你使用 Pepi / ShadowRay)"
				if [[ $v2ray_transport_opt == 4 ]]; then
					echo
					echo " 请在 Pepi / ShadowRay 配置界面打开 TLS (Enable TLS) (如果你使用 Pepi / ShadowRay)"
					if [[ $ws_path ]]; then
						echo
						echo -e "$yellow 记得要将 WebSocket 路径 (WS path) 设置为: ${cyan}/${ws_path}$none"
					fi
				fi
			elif [[ $ios_qr ]]; then
				echo -e "$red 生成适用于 Pepi / ShadowRay 的二维码链接 出错.... $none 请尝试使用${cyan} v2ray qr ${none}重新生成"
			else
				echo -e "$red 帅帅的提示...此 V2Ray 配置不支持 Pepi / ShadowRay...$none"
			fi
			echo
			echo
			echo "---------- Shadowsocks 二维码链接 -------------"
			echo
			echo -e "$yellow 链接 = $cyan${link2}$none"
			echo
			echo -e " 温馨提示...$red Shadowsocks Win 4.0.6 $none客户端可能无法识别该二维码"
			echo
			echo
			echo "----------------------------------------------------------------"
			echo
			echo "备注...链接将在 14 天后失效"
			echo
			echo "提醒...请不要把链接分享出去...除非你有特别的理由...."
			echo
		else
			echo
			echo -e "$red 哎呀呀呀...出错咯...$none"
			echo
			echo -e " 请尝试使用${cyan} v2ray qr ${none}生成 V2Ray 配置信息二维码"
			echo
			echo -e " 请尝试使用${cyan} v2ray ssqr ${none}生成 Shadowsocks 配置信息二维码"
			echo
		fi

		rm -rf /tmp/233blog_shadowsocks.png
		rm -rf /tmp/233blog_shadowsocks.txt
	else
		local vmess="vmess://$(cat /etc/v2ray/vmess_qr.json | base64)"
		echo $vmess >/etc/v2ray/vmess.txt
		cat /etc/v2ray/vmess.txt | qrencode -s 50 -o /tmp/233blog_v2ray.png
		local random1=$(echo $RANDOM-$RANDOM-$RANDOM | base64)
		local link1=$(curl -s --upload-file /tmp/233blog_v2ray.png "https://transfer.sh/${random1}_233blog_v2ray.png")
		if [[ $link1 ]]; then
			echo
			echo "---------- V2Ray 二维码链接 -------------"
			echo
			echo -e "$yellow 适用于 V2RayNG / Kitsunebi = $cyan${link1}$none"
			echo
			if [[ $ios_qr && $link3 ]]; then
				echo -e "$yellow 适用于 Pepi / ShadowRay = $cyan${link3}$none"
				echo
				echo " 请在 Pepi / ShadowRay 配置界面将 Alter Id 设置为 233 (如果你使用 Pepi / ShadowRay)"
				if [[ $v2ray_transport_opt == 4 ]]; then
					echo
					echo " 请在 Pepi / ShadowRay 配置界面打开 TLS (Enable TLS) (如果你使用 Pepi / ShadowRay)"
					if [[ $ws_path ]]; then
						echo
						echo -e "$yellow 记得要将 WebSocket 路径 (WS path) 设置为: ${cyan}/${ws_path}$none"
					fi
				fi
			elif [[ $ios_qr ]]; then
				echo -e "$red 生成适用于 Pepi / ShadowRay 的二维码链接 出错.... $none 请尝试使用${cyan} v2ray qr ${none}重新生成"
			else
				echo -e "$red 帅帅的提示...此 V2Ray 配置不支持 Pepi / ShadowRay...$none"
			fi
			echo
			echo
			echo "----------------------------------------------------------------"
			echo
			echo "备注...链接将在 14 天后失效"
			echo
			echo "提醒...请不要把链接分享出去...除非你有特别的理由...."
			echo
		else
			echo
			echo -e "$red 哎呀呀呀...出错咯...请重试$none"
			echo
			echo -e " 请尝试使用${cyan} v2ray qr ${none}生成 V2Ray 配置信息二维码"
			echo
		fi
	fi
	rm -rf /tmp/233blog_v2ray.png
	rm -rf /etc/v2ray/vmess_qr.json
	rm -rf /etc/v2ray/vmess.txt
	if [[ $ios_qr ]]; then
		rm -rf /tmp/233blog_shadowray_qr.png
		rm -rf /etc/v2ray/shadowray_qr.txt
	fi

}
install() {
	if [[ -f /usr/bin/v2ray/v2ray && -f /etc/v2ray/config.json ]] && [[ -f $backup && -d /etc/v2ray/233boy/v2ray ]]; then
		echo
		echo " 大佬...你已经安装 V2Ray 啦...无需重新安装"
		echo
		echo -e " $yellow输入 ${cyan}v2ray${none} $yellow即可管理 V2Ray${none}"
		echo
		exit 1
	fi
	v2ray_config
	blocked_hosts
	shadowsocks_config
	install_info
	try_enable_bbr
	[ $caddy ] && domain_check
	install_v2ray
	[ $caddy ] && install_caddy
	get_ip
	config
	show_config_info
	create_qr_link_ask
}
uninstall() {

	if [[ -f /usr/bin/v2ray/v2ray && -f /etc/v2ray/config.json ]] && [[ -f $backup && -d /etc/v2ray/233boy/v2ray ]]; then
		while :; do
			echo
			read -p "$(echo -e "是否卸载 ${yellow}V2Ray$none [${magenta}Y/N$none]:")" uninstall_v2ray_ask
			if [[ -z $uninstall_v2ray_ask ]]; then
				error
			else
				case $uninstall_v2ray_ask in
				Y | y)
					is_uninstall_v2ray=true
					echo
					echo -e "$yellow 卸载 V2Ray = ${cyan}是${none}"
					echo
					break
					;;
				N | n)
					echo
					echo -e "$red 卸载已取消...$none"
					echo
					break
					;;
				*)
					error
					;;
				esac
			fi
		done
		if [[ $(sed -n '29p' $backup) == "true" ]]; then
			caddy_installed=true
		fi

		if [[ $caddy_installed ]] && [[ -f /usr/local/bin/caddy && -f /etc/caddy/Caddyfile ]]; then
			while :; do
				echo
				read -p "$(echo -e "是否卸载 ${yellow}Caddy$none [${magenta}Y/N$none]:")" uninstall_caddy_ask
				if [[ -z $uninstall_caddy_ask ]]; then
					error
				else
					case $uninstall_caddy_ask in
					Y | y)
						is_uninstall_caddy=true
						echo
						echo -e "$yellow 卸载 Caddy = ${cyan}是${none}"
						echo
						break
						;;
					N | n)
						echo
						echo -e "$yellow 卸载 Caddy = ${cyan}否${none}"
						echo
						break
						;;
					*)
						error
						;;
					esac
				fi
			done
		fi

		if [[ $is_uninstall_v2ray && $is_uninstall_caddy ]]; then
			pause
			echo

			shadowsocks=$(sed -n '31p' $backup)

			if [[ $shadowsocks == "true" ]]; then
				ssport=$(sed -n '33p' $backup)
				del_port $ssport
			fi

			v2ray_transport_opt=$(sed -n '17p' $backup)
			v2ray_port=$(sed -n '19p' $backup)
			if [[ $v2ray_transport_opt == "4" ]]; then
				del_port "80"
				del_port "443"
				del_port $v2ray_port
			elif [[ $v2ray_transport_opt -ge 9 ]]; then
				del_port $v2ray_port
				del_port "multiport"
			else
				del_port $v2ray_port
			fi

			[ $cmd == "apt-get" ] && rm -rf /etc/network/if-pre-up.d/iptables

			v2ray_pid=$(ps ux | grep "/usr/bin/v2ray/v2ray" | grep -v grep | awk '{print $2}')
			# [ $v2ray_pid ] && systemctl stop v2ray
			[ $v2ray_pid ] && do_service stop v2ray

			rm -rf /usr/bin/v2ray
			rm -rf /usr/local/bin/v2ray
			rm -rf /etc/v2ray
			rm -rf /var/log/v2ray

			caddy_pid=$(pgrep "caddy")
			# [ $caddy_pid ] && systemctl stop caddy
			[ $caddy_pid ] && do_service stop caddy
			rm -rf /usr/local/bin/caddy
			rm -rf /etc/caddy
			rm -rf /etc/ssl/caddy

			if [[ $systemd ]]; then
				systemctl disable v2ray >/dev/null 2>&1
				rm -rf /lib/systemd/system/v2ray.service
				systemctl disable caddy >/dev/null 2>&1
				rm -rf /lib/systemd/system/caddy.service
			else
				update-rc.d -f caddy remove >/dev/null 2>&1
				update-rc.d -f v2ray remove >/dev/null 2>&1
				rm -rf /etc/init.d/caddy
				rm -rf /etc/init.d/v2ray
			fi

			# clear
			echo
			echo -e "$green V2Ray 卸载完成啦 ....$none"
			echo
			echo "如果你觉得这个脚本有哪些地方不够好的话...请告诉我"
			echo
			echo "反馈问题: https://github.com/233boy/v2ray/issus"
			echo

		elif [[ $is_uninstall_v2ray ]]; then
			pause
			echo

			shadowsocks=$(sed -n '31p' $backup)

			if [[ $shadowsocks == "true" ]]; then
				ssport=$(sed -n '33p' $backup)
				del_port $ssport
			fi

			v2ray_transport_opt=$(sed -n '17p' $backup)
			v2ray_port=$(sed -n '19p' $backup)
			if [[ $v2ray_transport_opt == "4" ]]; then
				del_port "80"
				del_port "443"
				del_port $v2ray_port
			elif [[ $v2ray_transport_opt -ge 9 ]]; then
				del_port $v2ray_port
				del_port "multiport"
			else
				del_port $v2ray_port
			fi

			[ $cmd == "apt-get" ] && rm -rf /etc/network/if-pre-up.d/iptables

			v2ray_pid=$(ps ux | grep "/usr/bin/v2ray/v2ray" | grep -v grep | awk '{print $2}')
			# [ $v2ray_pid ] && systemctl stop v2ray
			[ $v2ray_pid ] && do_service stop v2ray
			rm -rf /usr/bin/v2ray
			rm -rf /usr/local/bin/v2ray
			rm -rf /etc/v2ray
			rm -rf /var/log/v2ray
			if [[ $systemd ]]; then
				systemctl disable v2ray >/dev/null 2>&1
				rm -rf /lib/systemd/system/v2ray.service
			else
				update-rc.d -f v2ray remove >/dev/null 2>&1
				rm -rf /etc/init.d/v2ray
			fi
			# clear
			echo
			echo -e "$green V2Ray 卸载完成啦 ....$none"
			echo
			echo "如果你觉得这个脚本有哪些地方不够好的话...请告诉我"
			echo
			echo "反馈问题: https://github.com/233boy/v2ray/issus"
			echo

		fi
	else
		echo -e "
		$red 大胸弟...你貌似毛有安装 V2Ray ....卸载个鸡鸡哦...$none

		备注...仅支持卸载使用我(233blog.com)提供的 V2Ray 一键安装脚本
		" && exit 1
	fi

}

args=$1
[ -z $1 ] && args="online"
case $args in
online)
	#hello world
	;;
local)
	local_install=true
	;;
*)
	echo
	echo -e " 大佬...你输入的这个参数 <$red $args $none> ...这个是什么鬼啊...脚本不认识它哇"
	echo
	echo -e " 这个辣鸡脚本仅支持输入$green local / online $none参数"
	echo
	echo -e " 输入$yellow local $none即是使用本地安装"
	echo
	echo -e " 输入$yellow online $none即是使用在线安装 (默认)"
	echo
	exit 1
	;;
esac

clear
while :; do
	echo
	echo "........... V2Ray 一键安装脚本 & 管理脚本 by 233blog.com .........."
	echo
	echo "帮助说明: https://233blog.com/post/16/"
	echo
	echo "搭建教程: https://233blog.com/post/17/"
	echo
	echo " 1. 安装"
	echo
	echo " 2. 卸载"
	echo
	if [[ $local_install ]]; then
		echo " 温馨提示.. 本地安装已启用 .."
		echo
	fi
	read -p "$(echo -e "请选择 [${magenta}1-2$none]:")" choose
	case $choose in
	1)
		install
		break
		;;
	2)
		uninstall
		break
		;;
	*)
		error
		;;
	esac
done

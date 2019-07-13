#!/usr/bin/env bash

function blue(){
    echo -e "\033[34;01m $1 \033[0m"
}
function green(){
    echo -e "\033[32;01m $1 \033[0m"
}
function red(){
    echo -e "\033[31;01m $1 \033[0m"
}
function yellow(){
    echo -e "\033[33;01m $1 \033[0m"
}

# 随机数生成
function rand(){
    min=$1
    max=$(($2-$min+1))
    num=$(date +%s%N)
    echo $(($num%$max+$min))
}

clear
# 切换目录
if [ ! -d "/etc/wireguard" ]; then
    mkdir /etc/wireguard
fi
cd /etc/wireguard

# 生成key
function mkkey() {
    privkey=`wg genkey`
    pubkey=`echo $privkey | wg pubkey`
}

# 生成服务器配置
function mkserver(){
    clear
    yellow $(ls)
    read -e -p "输入服务器配置文件名[默认为 wg0]: " sname
    if [ -z "${sname}" ];then
        sname="wg0"
    fi
    sconf=${sname}.conf
    if [ -f "${sconf}" ]; then
        red " 文件 \"${sconf}\" 已存在!! "
        sleep 2s
        menu
    fi
    read -e -p "设置虚拟局域网络地址[默认为 10.12.12.1]: " svaddr
    if [ -z "${svaddr}" ];then
        svaddr="10.12.12.1"
    fi
    read -e -p "设置服务器监听端口[默认10000-60000随机]：" port
    if [ -z "${port}" ]; then
        port=$(rand 10000 60000)
    fi
    mkkey

# 生成服务器配置文件
cat > ${sconf} << EOFF
# Server: ${sconf}
# privatekey: ${privkey}
# pubkey: ${pubkey}

# CentOS运行Wireguard服务器时需要设置如下防火墙策略，并且开启IP转发功能。
# firewall cmd:
# firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=${svaddr}/24 masquerade"
# firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i ${sname} -o `ip route|grep default|awk '{print $5}'|head -1` -j ACCEPT

# firewall-cmd --permanent --remove-rich-rule="rule family=ipv4 source address=${svaddr}/24 masquerade"
# firewall-cmd --permanent --direct --remove-rule ipv4 filter FORWARD 0 -i ${sname} -o `ip route|grep default|awk '{print $5}'|head -1` -j ACCEPT

# ipv6
# firewall-cmd --permanent --add-rich-rule="rule family=ipv6 source address=fd10:db31:0203:ab31::1/64 masquerade"
# firewall-cmd --permanent --direct --add-rule ipv6 filter FORWARD 0 -i ${sname} -o `ip route|grep default|awk '{print $5}'|head -1` -j ACCEPT

# firewall-cmd --permanent --remove-rich-rule="rule family=ipv6 source address=fd10:db31:0203:ab31::1/64 masquerade"
# firewall-cmd --permanent --direct --remove-rule ipv6 filter FORWARD 0 -i ${sname} -o `ip route|grep default|awk '{print $5}'|head -1` -j ACCEPT
# firewall-cmd --reload

[Interface]
# Ubuntu服务器运行 WireGuard 时要执行的 iptables 防火墙规则，用于打开NAT转发之类的。
# 如果你的服务器主网卡名称不是 eth0 ，那么请修改下面防火墙规则中最后的 eth0 为你的主网卡名称。
#PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o `ip route|grep default|awk '{print $5}'|head -1` -j MASQUERADE
#; ip6tables -A FORWARD -i %i -j ACCEPT; ip6tables -t nat -A POSTROUTING -o `ip route|grep default|awk '{print $5}'|head -1` -j MASQUERADE
#PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o `ip route|grep default|awk '{print $5}'|head -1` -j MASQUERADE
#; ip6tables -D FORWARD -i %i -j ACCEPT; ip6tables -t nat -D POSTROUTING -o `ip route|grep default|awk '{print $5}'|head -1` -j MASQUERADE

# ServerPriateKey
PrivateKey = ${privkey}
Address = ${svaddr}/24
ListenPort = ${port}

EOFF
}

# 生成客户端配置
function mkclient(){
    clear
    blue "$(cat $sconf)"
    read -e -p "输入客户端配置文件名称[默认为 \"client\"]: " cname
    if [ -z "${cname}" ]; then
        cname="client"
    fi
    webip=$(curl -s cip.cc|head -1|awk '{print $3}')
    echo "Webip ${webip}"
    if [ -n "${webip}" ]; then
        serverip=${webip}
    else
        red "未采集到IP！！请手动输入！！"
    fi
    read -e -p "输入服务器IP[默认 ${serverip}]: " saddr
    if [ -z "${saddr}" ]; then
        saddr=${serverip}
    fi
    read -e -p "设置客户端转发IP段[默认为 0.0.0.0/0, ::0/0 表示全局转发]: " allowip
    if [ -z "${allowip}" ]; then
        allowip="0.0.0.0/0"
    fi
    caddra=$(grep Address ${sconf}|awk -F '[ .]' '{print $3"."$4"."$5"."}')
    spubkey=$(grep "# pubkey:" ${sconf}|awk '{print $3}')
    sport=$(grep "ListenPort" ${sconf}|awk '{print $3}')
    ipnum=$(grep AllowedIPs ${sconf}|tail -1|awk -F '[./]' '{print $4}')
    if [ -z "${ipnum}" ]; then
        ipnum=1
    fi
    newnum=$((10#${ipnum}+1))
    read -e -p "输入生成客户端文件个数[默认为 1 ]: " clientnums
    if [ -z "${clientnums}" ]; then
        clientnums=1
    fi
    endnum=$((10#${ipnum}+${clientnums}))
    # 写入客户端配置文件
    for (( i=${newnum}; i <= ${endnum}; i++ ))
    do
        cconf=${cname}${i}.conf
        # 判断客户端配置文件是否存在
        if [ -f "${cconf}" ]; then
            red "客户端文件 \"$cconf\" 已经存在!!"
            exit
        fi
        # 判断客户端IP是否已经使用
        clienIP=$(cat $sconf |grep "${caddra}${i}/32")
        if [ -n "${clienIP}" ]; then
            red "客户端 IP \"${caddra}${i}\" 已经使用!!"
            exit
        fi
        mkkey
cat > ${cconf} << EOFF
# Client: ${cconf}
# privatekey: ${privkey}
# pubkey: ${pubkey}

[Interface]
# ClientPrivateKey
PrivateKey = ${privkey}
Address = ${caddra}${i}/24
# Switch DNS server while connected
DNS = 1.1.1.1

[Peer]
# ServerPublicKey
PublicKey = ${spubkey}
Endpoint = ${saddr}:${sport}
AllowedIPs = ${allowip}
PersistentKeepalive = 15

EOFF

# 给服务器增加[Peer]配置
cat >> ${sconf} << EOFE
[Peer]
# ${cconf}
# ClientPublicKey
PublicKey = ${pubkey}
AllowedIPs = ${caddra}${i}/32

EOFE
    done
    
    clear
    blue "$(cat ${sconf})"
}

# 菜单
function menu(){
    clear
    echo
    green " 1. 创建服务器配置"
    green " 2. 增加客户端配置"
    yellow " 0. 退出脚本"
    echo
    read -e -p "请输入数字:" num
    case "$num" in
    1)
    mkserver
    mkclient
    ;;
    2)
    yellow "$(ls)"
    read -e -p "输入匹配的服务端配置文件名字[默认为 wg0.conf]: " sconf
    if [ -z ${sconf} ]; then
        sconf="wg0.conf"
    fi
    if [ ! -f "$sconf" ]; then
        red "\"$sconf\" 不存在！！"
        yellow $(ls)
        sleep 2s
        menu
    fi
    mkclient
    ;;
    0)
    exit 1
    ;;
    *)
    clear
    red "请输入正确数字"
    sleep 2s
    menu
    ;;
    esac
}

menu

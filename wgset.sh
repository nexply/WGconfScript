#!/bin/bash
clear
# 切换目录
if [ ! -f "$sconf" ]; then
mkdir /etc/wireguard
fi
cd /etc/wireguard

# 生成key
function mkkey {
privkey=`wg genkey`
pubkey=`echo $privkey | wg pubkey`
}

# 生成服务器配置
function server {
clear
ls
read -e -p "Enter the server profile name: " sname
sconf=${sname}.conf
if [ -f "$sconf" ]; then
echo -e "\033[31m\033[01m Profile \"$sconf\" already exists!! \033[0m"
exit
fi
read -e -p "Set the VPN server address[10.*.*.1]: " svaddr
read -e -p "Enter ListenPort: " port
mkkey

# 写入服务器配置文件
cat << EOFF >> $sconf
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Server
# privatekey: $privkey
# pubkey: $pubkey
# firewall cmd:
# firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=${svaddr}/24 masquerade"
# firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i ${sname} -o `ip route|grep default|awk -F"dev" '{print $2}'|awk '{print $1}'` -j ACCEPT
# firewall-cmd --reload
# 
# firewall-cmd --permanent --remove-rich-rule="\`firewall-cmd --list-rich-rules\`"
# firewall-cmd --permanent --direct --remove-rule \`firewall-cmd --direct --get-all-rules\`
# firewall-cmd --reload

[Interface]
# 运行 WireGuard 时要执行的 iptables 防火墙规则，用于打开NAT转发之类的。
# 如果你的服务器主网卡名称不是 eth0 ，那么请修改下面防火墙规则中最后的 eth0 为你的主网卡名称。
#PostUp = iptables -A FORWARD -i ${sname} -j ACCEPT; iptables -A FORWARD -o ${sname} -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# 停止 WireGuard 时要执行的 iptables 防火墙规则，用于关闭NAT转发之类的。
# 如果你的服务器主网卡名称不是 eth0 ，那么请修改下面防火墙规则中最后的 eth0 为你的主网卡名称。
#PostDown = iptables -D FORWARD -i ${sname} -j ACCEPT; iptables -D FORWARD -o ${sname} -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# ServerPriateKey
PrivateKey = $privkey
Address = ${svaddr}/24
ListenPort = $port

EOFF
}

# 生成客户端配置
function clien {
clear
cat $sconf
read -e -p "Enter the client profile name: " cname
#cconf=${cname}.conf
#if [ -f "$cconf" ]; then
#	echo "Profile $cconf already exists!!"
#	exit
#fi
#read -e -p "Set the VPN client address[10.*.*.*]: " caddr
ip a|grep inet|grep brd|awk '{print $1"\t"$2}'
webip=`curl -s ip.6655.com/ip.aspx`
echo "webip	$webip"
read -e -p "Enter server address[serverIP]: " saddr
read -e -p "Enter AllowedIPs[0.0.0.0/0]: " allowip

caddra=`cat $sconf |grep Address | awk '{print $3}' | awk -F. '{print $1"."$2"."$3"."}'`
spubkey=`cat $sconf | grep "# pubkey:" | awk '{print $3}'`
sport=`cat $sconf | grep "ListenPort =" | awk '{print $3}'`

ls
read -e -p "Enter first number: " numa
read -e -p "Enter last number: " numb

# 写入客户端配置文件
while [ ${numb} -ge ${numa} ]
do

cconf=${cname}${numa}.conf
# 判断客户端配置文件是否存在
if [ -f "$cconf" ]; then
echo -e "\033[31m\033[01m Profile \"$cconf\" already exists!! \033[0m"
exit
fi
# 判断客户端IP是否已经使用
clienIP=`cat $sconf |grep "${caddra}${numa}/32"`
if [ -n "${clienIP}" ]; then
echo -e "\033[31m\033[01m Clien'IP \"${caddra}${numa}\" already exists!! \033[0m"
exit
fi

mkkey
cat << EOFF > $cconf
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Client
# privatekey: $privkey
# pubkey: $pubkey

[Interface]
Address = ${caddra}${numa}/24
# ClientPrivateKey
PrivateKey = $privkey
# Switch DNS server while connected
# DNS = 1.1.1.1

[Peer]
# ServerPublicKey
PublicKey = $spubkey
Endpoint = ${saddr}:$sport
AllowedIPs = $allowip
#PersistentKeepalive = 25

EOFF

# 给服务器增加[Peer]配置
cat << EOFE >> $sconf
[Peer]
# $cconf
# ClientPublicKey
PublicKey = $pubkey
AllowedIPs = ${caddra}${numa}/32

EOFE

numa=$[${numa}+1]
done

clear
cat $sconf
}

# 菜单
PS3="Enter option: "
select option in "Create server configuration" "Add client configuration"
do
case $option in
"Create server configuration")
server
clien
exit ;;
"Add client configuration")
ls
read -e -p "Enter the server profile name[**.conf]: " sconf
if [ ! -f "$sconf" ]; then
echo -e "\033[31m\033[01m Profile \"$sconf\" does not exist!! \033[0m"
ls
exit
fi
clien
exit ;;
*)
echo -e "\033[31m\033[01m Sorry, wrong selection!! \033[0m";;
esac
done

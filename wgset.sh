#!/bin/bash
clear
# 切换目录
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
read -e -p "Enter name of the server file: " sname
sconf=${sname}.conf
if [ -f "$sconf" ]; then
echo "Profile $sconf already exists!!"
exit
fi
read -e -p "Set VPN server address[10.*.*.1]: " svaddr
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
read -e -p "Enter name of the client configuration file: " cname
cconf=${cname}.conf
if [ -f "$cconf" ]; then
echo "Profile $cconf already exists!!"
exit
fi
read -e -p "Set VPN client address[10.*.*.*]: " cvaddr
ip a|grep inet|grep brd|awk '{print $1"\t"$2}'
webip=`curl -s "http://checkip.dyndns.org/"|cut -d "<" -f7|cut -c 26-`
echo "webip	$webip"
read -e -p "Enter server address[serverIP]: " saddr
read -e -p "Enter AllowedIPs[0.0.0.0/0]: " allowip

spubkey=`cat $sconf | grep "# pubkey:" | awk '{print $3}'`
sport=`cat $sconf | grep "ListenPort =" | awk '{print $3}'`
mkkey

# 写入客户端配置文件
cat << EOFF > $cconf
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Client
# privatekey: $privkey
# pubkey: $pubkey

[Interface]
Address = ${cvaddr}/24
# ClientPrivateKey
PrivateKey = $privkey
# Switch DNS server while connected
# DNS = 1.1.1.1

[Peer]
# ServerPublicKey
PublicKey = $spubkey
Endpoint = ${saddr}:$sport
AllowedIPs = $allowip
PersistentKeepalive = 25

EOFF

# 给服务器增加[Peer]配置
cat << EOFE >> $sconf
[Peer]
# $cname
# ClientPublicKey
PublicKey = $pubkey
AllowedIPs = ${cvaddr}/32

EOFE
clear
cat $sconf
cat $cconf
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
read -e -p "Enter name of the server configuration file[**.conf]: " sconf
if [ ! -f "$sconf" ]; then
echo "Profile $sconf does not exist!!"
ls
exit
fi
clien
exit ;;
*)
echo "Sorry, wrong selection!!";;
esac
done

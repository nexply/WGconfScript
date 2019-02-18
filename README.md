# WireGuard configuration generation script
# WireGuard 配置文件生成脚本
> 注意：服务器一定要打开转发功能 

```
向 /etc/sysctl.conf 添加

net.ipv4.ip_forward = 1
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

net.ipv6.conf.all.forwarding=1
exho "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
```

> 目前只测试了centos\ubuntu系统，其他类型系统请自行根据配置文件内的注释 修改防火墙规则。

```
# ipv4:

firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=10.0.0.1/24 masquerade"
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i %i -o `ip route|grep default|awk '{print $5}'` -j ACCEPT

firewall-cmd --permanent --remove-rich-rule="rule family=ipv4 source address=10.0.0.1/24 masquerade"
firewall-cmd --permanent --direct --remove-rule ipv4 filter FORWARD 0 -i %i -o `ip route|grep default|awk '{print $5}'` -j ACCEPT

# ipv6

firewall-cmd --permanent --add-rich-rule="rule family=ipv6 source address=fd10:db31:0203:ab31::1/64 masquerade"
firewall-cmd --permanent --direct --add-rule ipv6 filter FORWARD 0 -i %i -o `ip route|grep default|awk '{print $5}'` -j ACCEPT

firewall-cmd --permanent --remove-rich-rule="rule family=ipv6 source address=fd10:db31:0203:ab31::1/64 masquerade"
firewall-cmd --permanent --direct --remove-rule ipv6 filter FORWARD 0 -i %i -o `ip route|grep default|awk '{print $5}'` -j ACCEPT

firewall-cmd --reload

#PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
#PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

#PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; ip6tables -A FORWARD -i %i -j ACCEPT; ip6tables -A FORWARD -o %i -j ACCEPT; ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
#PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE; ip6tables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

```

> 安装WireGuard后，创建/etc/wireguard文件夹。

> 将脚本下载到/etc/wireguard文件夹内。

```sh
mkdir /etc/wireguard
cd /etc/wireguard
git clone https://github.com/nexply/WGconfScript.git
cd ./WGconfScript
bash wgset.sh
```

> removeip.py 脚本可从某网段排除特定IP，方便特殊情况配置 “AllowedIPs”

```
cd /etc/wireguard/WGconfScript
pip install -r requirement.txt
python removeip.py 0.0.0.0/0 -r 192.168.1.0/24
```

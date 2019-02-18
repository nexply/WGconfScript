# WireGuard configuration generation script
# WireGuard 配置文件生成脚本

> 目前只测试了centos系统，其他类型系统请自行修改 防火墙规则。

> 安装WireGuard后，创建/etc/wireguard文件夹。

> 将脚本下载到/etc/wireguard文件夹内。

> removeip.py 脚本可从某网段排除特定IP，方便特殊情况配置 “AllowedIPs”

```
pip install -r requirement.txt
python removeip.py 0.0.0.0/0 -r 192.168.1.0/24
```

## 运行配置脚本
```sh
cd /etc/wireguard
bash wgset.sh
```

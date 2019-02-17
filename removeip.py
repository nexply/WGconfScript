#!/usr/bin/env python
# coding=utf-8

from argparse import ArgumentParser

from netaddr import IPNetwork, IPSet


def main():
    parser = ArgumentParser(description='支持从某个网段排除特定IP！')
    parser.add_argument('network', type=str, metavar='网段',
                        help='如：192.168.1.0/24')
    parser.add_argument('ip', type=str, metavar='要排除的IP',
                        help='如：192.168.1.128')
    args = parser.parse_args()
    try:
        ipnet = IPNetwork(args.network).cidr
        ips = IPSet([ipnet])
    except Exception as e:
        print '输入网段错误：{}'.format(e)
    try:
        ips.remove(args.ip)
    except Exception as e:
        print '输入IP错误：{}'.format(e)
    print '\n拆分后的IP段为：\n'
    print ', '.join(outip for outip in map(str, ips.iter_cidrs()))


if __name__ == '__main__':
    main()

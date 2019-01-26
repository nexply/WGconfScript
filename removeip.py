#!/usr/bin/env python
# coding=utf-8

from netaddr import IPNetwork, IPAddress, IPSet
from argparse import ArgumentParser


def main():
    parser = ArgumentParser(description=u'支持从某个网段排除特定IP！')
    parser.add_argument('network', type=str, metavar=u'网段',
                        help=u'如：192.168.1.0/24')
    parser.add_argument('ip', type=str, metavar=u'要排除的IP',
                        help=u'如：192.168.1.128')
    args = parser.parse_args()

    try:
        ipnet = IPNetwork(args.network).cidr
    except Exception as e:
        print u'输入网段错误：{}'.format(e)

    try:
        nip = IPAddress(args.ip)
    except Exception as e:
        print u'输入IP错误：{}'.format(e)

    # ip = IPNetwork('192.168.1.23/16').cidr
    # nip = IPAddress('192.168.1.123')

    ips = IPSet([ipnet])
    ips.remove(nip)

    print ', '.join(outip for outip in map(str, ips.iter_cidrs()))


if __name__ == '__main__':
    main()

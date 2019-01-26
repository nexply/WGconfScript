#!/usr/bin/env python
# coding=utf-8

from netaddr import IPNetwork, IPAddress, IPSet
from argparse import ArgumentParser


def main():
    parser = ArgumentParser(description=u'需要输入“网段”和“IP”')
    parser.add_argument('network', type=str, metavar=u'网段',
                        help=u'输入网段，如：192.168.1.0/24')
    parser.add_argument('ip', type=str, metavar='IP',
                        help=u'输入要排除的ip，如：192.168.1.128')
    args = parser.parse_args()

    ip = IPNetwork(args.network).cidr
    nip = IPAddress(args.ip)

    # ip = IPNetwork('192.168.1.23/16').cidr
    # nip = IPAddress('192.168.1.123')

    ips = IPSet([ip])
    ips.remove(nip)

    print ', '.join(outip for outip in map(str, ips.iter_cidrs()))


if __name__ == '__main__':
    main()

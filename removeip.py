#!/usr/bin/env python
# coding=utf-8

from argparse import ArgumentParser

from netaddr import IPNetwork, IPSet


def main():
    parser = ArgumentParser(description='支持从某个‎CIDR网段排除特定IP！')
    parser.add_argument('netstr', type=str, metavar='‎CIDR',
                        help='需要排除IP的网段，如：0.0.0.0/0')
    parser.add_argument('-r', type=str, metavar='IP',
                        help='排除的IP，支持同时排除多个，支持网段，例子: -r 192.168.1.128 -r 192.168.2.0/24',
                        action='append')
    parser.add_argument_group()
    args = parser.parse_args()
    try:
        ipnet = IPNetwork(args.netstr).cidr
        ips = IPSet([ipnet])
    except Exception as e:
        print('CIDR 输入错误：{}'.format(e))
    try:
        if args.r:
            for i in args.r:
                ips.remove(i)
    except Exception as e:
            print('-r IP输入错误：{}'.format(e))
    print('\n拆分后的网段段为：\n')
    print(','.join(outip for outip in map(str, ips.iter_cidrs())))


if __name__ == '__main__':
    main()

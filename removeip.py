#!/usr/bin/env python
# coding=utf-8

from argparse import ArgumentParser

from netaddr import IPNetwork, IPSet


def main():
    parser = ArgumentParser(description='支持从某个‎CIDR网段排除特定IP！')
    parser.add_argument('netstr', type=str, metavar='‎CIDR网段',
                        help='如：192.168.1.0/24')
    parser.add_argument('-r', '--remove', type=str, metavar='要排除的IP或‎CIDR网段',
                        help='如：192.168.1.128 或 192.168.2.0/24',
                        action='append')
    args = parser.parse_args()
    try:
        ipnet = IPNetwork(args.netstr).cidr
        ips = IPSet([ipnet])
    except Exception as e:
        print 'CIDR网段输入错误：{}'.format(e)
    for i in args.remove:
        try:
            ips.remove(i)
        except Exception as e:
            print '要排除的IP输入错误：{}'.format(e)
    print '\n拆分后的网段段为：\n'
    print ', '.join(outip for outip in map(str, ips.iter_cidrs()))


if __name__ == '__main__':
    main()

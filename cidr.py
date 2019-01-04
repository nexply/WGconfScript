#!/usr/bin/env python
# coding=utf-8

import sys
import netaddr

ip = netaddr.IPNetwork(sys.argv[1])
nip = netaddr.IPAddress(sys.argv[2])

ipf = [netaddr.IPAddress(ip.first), netaddr.IPAddress(nip.value + 1)]
ipl = [netaddr.IPAddress(nip.value - 1), netaddr.IPAddress(ip.last)]

print ""
for i in range(2):
    startip = ipf[i]
    endip = ipl[i]
    cidrs = netaddr.iprange_to_cidrs(startip, endip)
    for k, iplist in enumerate(cidrs):
        print "%s," % iplist,

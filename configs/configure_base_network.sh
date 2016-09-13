#!/bin/bash
cat >/etc/sysconfig/network-scripts/ifcfg-enp0s4 <<EOF
DEVICE="enp0s4"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
USERCTL="yes"
PEERDNS="yes"
IPV6INIT="no"
PERSISTENT_DHCLIENT="1"
EOF
ifup enp0s4

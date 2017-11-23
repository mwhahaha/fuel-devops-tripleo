#!/bin/bash
# disable dhcp on the other interfaces
sed -ir 's/ONBOOT=yes/ONBOOT=no/' /etc/sysconfig/network-scripts/ifcfg-enp0s4
sed -ir 's/ONBOOT=yes/ONBOOT=no/' /etc/sysconfig/network-scripts/ifcfg-enp0s5
sed -ir 's/ONBOOT=yes/ONBOOT=no/' /etc/sysconfig/network-scripts/ifcfg-enp0s6

# the public network is the 1st one
cat >/etc/sysconfig/network-scripts/ifcfg-enp0s3 <<EOF
DEVICE="enp0s3"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
USERCTL="yes"
PEERDNS="yes"
IPV6INIT="no"
PERSISTENT_DHCLIENT="1"
EOF
ifup enp0s3

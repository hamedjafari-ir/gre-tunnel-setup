#!/bin/bash

function connect_from_iran_to_kharej() {
  echo "Enter Iran IPv4:"
  read IP_IRAN
  echo "Enter Kharej IPv4:"
  read IP_KHAREJ

  echo "Setting up 6to4 tunnel on Iran server..."
  ip tunnel add 6to4_To_KH mode sit remote $IP_KHAREJ local $IP_IRAN
  ip -6 addr add fde8:b030:25cf::de01/64 dev 6to4_To_KH
  ip link set 6to4_To_KH mtu 1480
  ip link set 6to4_To_KH up

  echo "Setting up GRE6 tunnel on Iran server..."
  ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote fde8:b030:25cf::de02 local fde8:b030:25cf::de01
  ip addr add 172.20.20.1/30 dev GRE6Tun_To_KH
  ip link set GRE6Tun_To_KH mtu 1436
  ip link set GRE6Tun_To_KH up
}

function connect_from_kharej_to_iran() {
  echo "Enter Kharej IPv4:"
  read IP_KHAREJ
  echo "Enter Iran IPv4:"
  read IP_IRAN

  echo "Setting up 6to4 tunnel on Kharej server..."
  ip tunnel add 6to4_To_IR mode sit remote $IP_IRAN local $IP_KHAREJ
  ip -6 addr add fde8:b030:25cf::de02/64 dev 6to4_To_IR
  ip link set 6to4_To_IR mtu 1480
  ip link set 6to4_To_IR up

  echo "Setting up GRE6 tunnel on Kharej server..."
  ip -6 tunnel add GRE6Tun_To_IR mode ip6gre remote fde8:b030:25cf::de01 local fde8:b030:25cf::de02
  ip addr add 172.20.20.2/30 dev GRE6Tun_To_IR
  ip link set GRE6Tun_To_IR mtu 1436
  ip link set GRE6Tun_To_IR up
}

function enable_nat_forwarding_iran() {
  echo "Enabling IP forwarding and NAT on Iran server..."
  sysctl -w net.ipv4.ip_forward=1
  iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 172.20.20.1
  iptables -t nat -A PREROUTING -j DNAT --to-destination 172.20.20.2
  iptables -t nat -A POSTROUTING -j MASQUERADE
}

function ping_test() {
  echo "1. Ping from Iran to Kharej (172.20.20.2)"
  ping -c 4 172.20.20.2
  echo "2. Ping from Kharej to Iran (172.20.20.1)"
  ping -c 4 172.20.20.1
}

while true; do
  clear
  echo "===== Tunnel Setup Script ====="
  echo "1. Connect Iran to Kharej"
  echo "2. Connect Kharej to Iran"
  echo "3. Enable NAT and IP Forwarding on Iran"
  echo "4. Ping Test"
  echo "5. Exit"
  echo "==============================="
  read -p "Select an option: " option

  case $option in
    1) connect_from_iran_to_kharej ;;
    2) connect_from_kharej_to_iran ;;
    3) enable_nat_forwarding_iran ;;
    4) ping_test ;;
    5) exit ;;
    *) echo "Invalid option"; sleep 1 ;;
  esac
done

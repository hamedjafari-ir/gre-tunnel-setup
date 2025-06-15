#!/bin/bash
# ---------------------------------------------------------------
# Script Name : setup-tunnel.sh
# Description : Auto/manual setup of 6to4 + GRE IPv6 tunnel
# Author      : Hamed Jafari
# GitHub      : https://github.com/hamedjafari-ir/gre-tunnel-setup
# Date        : 2025-06-15
# License     : MIT
# ---------------------------------------------------------------
set -e

function check_and_install_tools() {
  echo "Checking required packages..."
  REQUIRED_TOOLS=("ip" "ping6" "iptables" "sysctl")

  if command -v apt >/dev/null 2>&1; then
    INSTALL_CMD="apt update && apt install -y"
  elif command -v yum >/dev/null 2>&1; then
    INSTALL_CMD="yum install -y"
  else
    echo "No supported package manager found (apt or yum required)."
    exit 1
  fi

  for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v $tool >/dev/null 2>&1; then
      echo "Installing: $tool"
      eval "$INSTALL_CMD $tool"
    fi
  done
}

function restart_server() {
  echo "Restarting server..."
  reboot
}

function setup_manual() {
  echo "You selected MANUAL mode."
  echo "Please connect to each server manually and run the respective commands."
  echo "Refer to documentation for all steps."
  read -p "Press Enter to return to menu..."
}

function setup_auto() {
  echo "Automatic tunnel setup selected."
  read -p "Enter Iran Server IPv4: " IP_IRAN
  read -p "Enter Kharej Server IPv4: " IP_KHAREJ
  read -p "Enter Iran Server SSH Username (usually root): " USER_IRAN
  read -p "Enter Kharej Server SSH Username (usually root): " USER_KHAREJ

  echo "Installing required tools on both servers..."
  ssh $USER_IRAN@$IP_IRAN "$(typeset -f check_and_install_tools); check_and_install_tools"
  ssh $USER_KHAREJ@$IP_KHAREJ "$(typeset -f check_and_install_tools); check_and_install_tools"

  echo "Setting up 6to4 tunnel on Iran server..."
  ssh $USER_IRAN@$IP_IRAN <<EOF
ip tunnel add 6to4_To_KH mode sit remote $IP_KHAREJ local $IP_IRAN 2>/dev/null || true
ip -6 addr add fde8:b030:25cf::de01/64 dev 6to4_To_KH 2>/dev/null || true
ip link set 6to4_To_KH mtu 1480
ip link set 6to4_To_KH up
EOF

  echo "Setting up 6to4 tunnel on Kharej server..."
  ssh $USER_KHAREJ@$IP_KHAREJ <<EOF
ip tunnel add 6to4_To_IR mode sit remote $IP_IRAN local $IP_KHAREJ 2>/dev/null || true
ip -6 addr add fde8:b030:25cf::de02/64 dev 6to4_To_IR 2>/dev/null || true
ip link set 6to4_To_IR mtu 1480
ip link set 6to4_To_IR up
EOF

  echo "Testing IPv6 connectivity..."
  ssh $USER_IRAN@$IP_IRAN "ping6 -c 3 fde8:b030:25cf::de02"
  ssh $USER_KHAREJ@$IP_KHAREJ "ping6 -c 3 fde8:b030:25cf::de01"

  echo "Setting up GRE6 tunnel on Iran server..."
  ssh $USER_IRAN@$IP_IRAN <<EOF
ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote fde8:b030:25cf::de02 local fde8:b030:25cf::de01 2>/dev/null || true
ip addr add 172.20.20.1/30 dev GRE6Tun_To_KH
ip link set GRE6Tun_To_KH mtu 1436
ip link set GRE6Tun_To_KH up
EOF

  echo "Setting up GRE6 tunnel on Kharej server..."
  ssh $USER_KHAREJ@$IP_KHAREJ <<EOF
ip -6 tunnel add GRE6Tun_To_IR mode ip6gre remote fde8:b030:25cf::de01 local fde8:b030:25cf::de02 2>/dev/null || true
ip addr add 172.20.20.2/30 dev GRE6Tun_To_IR
ip link set GRE6Tun_To_IR mtu 1436
ip link set GRE6Tun_To_IR up
EOF

  echo "Testing GRE6 tunnel connectivity..."
  ssh $USER_IRAN@$IP_IRAN "ping -c 3 172.20.20.2"
  ssh $USER_KHAREJ@$IP_KHAREJ "ping -c 3 172.20.20.1"

  echo "Enabling IP forwarding and NAT on Iran server..."
  ssh $USER_IRAN@$IP_IRAN <<EOF
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 172.20.20.1
iptables -t nat -A PREROUTING -j DNAT --to-destination 172.20.20.2
iptables -t nat -A POSTROUTING -j MASQUERADE
EOF

  echo "✅ Tunnel successfully configured and tested!"
  read -p "Press Enter to return to menu..."
}

function about_script() {
  clear
  echo "=================================================="
  echo " GRE + 6to4 Tunnel Setup Script"
  echo " Author      : Hamed Jafari"
  echo " GitHub      : https://github.com/hamedjafari-ir/gre-tunnel-setup"
  echo " Created on  : 2025-06-15"
  echo " Description : Automates or guides manual setup of"
  echo "               IPv6 SIT + GRE tunnels between Iran"
  echo "               and Kharej servers."
  echo " License     : MIT"
  echo "=================================================="
  read -p "Press Enter to return to menu..."
}

function menu() {
  while true; do
    clear
    echo "========= GRE + 6to4 Tunnel Setup Script ========="
    echo "1. Automatic Configuration (Iran <-> Kharej)"
    echo "2. Manual Step-by-Step Guide"
    echo "3. Restart Server"
    echo "4. Exit"
    echo "5. About this script"
    echo "=================================================="
    read -p "Select an option: " choice

    case $choice in
      1) setup_auto ;;
      2) setup_manual ;;
      3) restart_server ;;
      4) exit ;;
      5) about_script ;;
      *) echo "Invalid option"; sleep 1 ;;
    esac
  done
}

menu

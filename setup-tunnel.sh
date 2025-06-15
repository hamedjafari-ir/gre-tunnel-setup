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

function show_loader() {
  local pid=$!
  local spin='-\|/'
  local i=0
  while kill -0 $pid 2>/dev/null; do
    i=$(( (i+1) %4 ))
    printf "\r[%c] Working..." "${spin:$i:1}"
    sleep 0.2
  done
  echo -e "\r[✓] Done         "
}

function run_remote() {
  local user=$1
  local host=$2
  local cmd=$3
  ssh -o StrictHostKeyChecking=no $user@$host "$cmd"
}

function check_and_install_tools() {
  echo "Checking required tools on local (Iran) server..."
  (
    if ! command -v ip >/dev/null; then sudo apt update && sudo apt install -y iproute2; fi
    if ! command -v ping6 >/dev/null; then sudo apt install -y iputils-ping; fi
    if ! command -v iptables >/dev/null; then sudo apt install -y iptables; fi
  ) & show_loader
}

function setup_auto() {
  echo "Automatic tunnel setup selected."

  read -p "Enter Kharej Server IPv4: " IP_KHAREJ
  read -p "Enter Iran Server IPv4 (current system IP): " IP_IRAN
  read -p "Enter Kharej SSH username (e.g., root): " USER_KHAREJ
  echo "Enter password for $USER_KHAREJ@$IP_KHAREJ (will be used automatically for all remote steps):"
  read -s PASS_KHAREJ

  check_and_install_tools

  echo "[Step 1] Setting up 6to4 tunnel on Iran server..."
  (
    ip tunnel add 6to4_To_KH mode sit remote $IP_KHAREJ local $IP_IRAN 2>/dev/null || true
    ip -6 addr add fde8:b030:25cf::de01/64 dev 6to4_To_KH 2>/dev/null || true
    ip link set 6to4_To_KH mtu 1480
    ip link set 6to4_To_KH up
  ) & show_loader

  echo "[Step 2] Setting up 6to4 tunnel on Kharej server..."
  (
    sshpass -p "$PASS_KHAREJ" ssh -o StrictHostKeyChecking=no $USER_KHAREJ@$IP_KHAREJ "
      ip tunnel add 6to4_To_IR mode sit remote $IP_IRAN local $IP_KHAREJ 2>/dev/null || true
      ip -6 addr add fde8:b030:25cf::de02/64 dev 6to4_To_IR 2>/dev/null || true
      ip link set 6to4_To_IR mtu 1480
      ip link set 6to4_To_IR up
    "
  ) & show_loader

  echo "[Step 3] Testing IPv6 connectivity..."
  ping6 -c 3 fde8:b030:25cf::de02 & show_loader
  sshpass -p "$PASS_KHAREJ" ssh $USER_KHAREJ@$IP_KHAREJ "ping6 -c 3 fde8:b030:25cf::de01" & show_loader

  echo "[Step 4] Setting up GRE6 tunnel on Iran server..."
  (
    ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote fde8:b030:25cf::de02 local fde8:b030:25cf::de01 2>/dev/null || true
    ip addr add 172.20.20.1/30 dev GRE6Tun_To_KH
    ip link set GRE6Tun_To_KH mtu 1436
    ip link set GRE6Tun_To_KH up
  ) & show_loader

  echo "[Step 5] Setting up GRE6 tunnel on Kharej server..."
  (
    sshpass -p "$PASS_KHAREJ" ssh $USER_KHAREJ@$IP_KHAREJ "
      ip -6 tunnel add GRE6Tun_To_IR mode ip6gre remote fde8:b030:25cf::de01 local fde8:b030:25cf::de02 2>/dev/null || true
      ip addr add 172.20.20.2/30 dev GRE6Tun_To_IR
      ip link set GRE6Tun_To_IR mtu 1436
      ip link set GRE6Tun_To_IR up
    "
  ) & show_loader

  echo "[Step 6] Test GRE6 tunnel IPv4"
  ping -c 3 172.20.20.2 & show_loader
  sshpass -p "$PASS_KHAREJ" ssh $USER_KHAREJ@$IP_KHAREJ "ping -c 3 172.20.20.1" & show_loader

  echo "[Step 7] Enabling NAT & Forwarding on Iran server..."
  (
    sysctl -w net.ipv4.ip_forward=1
    iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 172.20.20.1
    iptables -t nat -A PREROUTING -j DNAT --to-destination 172.20.20.2
    iptables -t nat -A POSTROUTING -j MASQUERADE
  ) & show_loader

  echo -e "\n✅ Tunnel successfully configured and verified!"
  read -p "Press Enter to return to menu..."
}

function about_script() {
  clear
  echo "=================================================="
  echo " GRE + 6to4 Tunnel Setup Script"
  echo " Author      : Hamed Jafari"
  echo " GitHub      : https://github.com/hamedjafari-ir/gre-tunnel-setup"
  echo " Created on  : 2025-06-15"
  echo " Description : Automates 6to4 + GRE6 tunnel between"
  echo "               Iran and Kharej with ping & NAT test"
  echo " License     : MIT"
  echo "=================================================="
  read -p "Press Enter to return to menu..."
}

function restart_server() {
  echo "Rebooting system now..."
  reboot
}

function setup_manual() {
  echo "Manual setup selected."
  echo "Please follow the documented step-by-step guide."
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

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

# Loader animation
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

# Validate SSH login
function validate_ssh() {
  echo "Checking SSH access to Kharej server..."
  until sshpass -p "$PASS_KHAREJ" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 $USER_KHAREJ@$IP_KHAREJ "echo connected" 2>/dev/null | grep -q connected; do
    echo "❌ Invalid username or password for Kharej server."
    read -p "Enter Kharej Server SSH Username (e.g., root): " USER_KHAREJ
    read -s -p "Enter password for $USER_KHAREJ@$IP_KHAREJ: " PASS_KHAREJ
    echo
  done
}

function setup_auto() {
  echo "Automatic tunnel setup selected."
  read -p "Enter Kharej Server IPv4: " IP_KHAREJ
  read -p "Enter Iran Server IPv4 (current system IP): " IP_IRAN
  read -p "Enter Kharej SSH username (e.g., root): " USER_KHAREJ
  read -s -p "Enter password for $USER_KHAREJ@$IP_KHAREJ: " PASS_KHAREJ
  echo

  validate_ssh

  echo "[1] Setting up 6to4 on Iran server..."
  (
    ip tunnel add 6to4_To_KH mode sit remote $IP_KHAREJ local $IP_IRAN 2>/dev/null || true
    ip -6 addr add fde8:b030:25cf::de01/64 dev 6to4_To_KH 2>/dev/null || true
    ip link set 6to4_To_KH mtu 1480
    ip link set 6to4_To_KH up
  ) & show_loader

  echo "[2] Setting up 6to4 on Kharej server..."
  (
    sshpass -p "$PASS_KHAREJ" ssh -o StrictHostKeyChecking=no $USER_KHAREJ@$IP_KHAREJ '
      ip tunnel add 6to4_To_IR mode sit remote '"$IP_IRAN"' local '"$IP_KHAREJ"' 2>/dev/null || true
      ip -6 addr add fde8:b030:25cf::de02/64 dev 6to4_To_IR 2>/dev/null || true
      ip link set 6to4_To_IR mtu 1480
      ip link set 6to4_To_IR up
    '
  ) & show_loader

  echo "[3] Testing IPv6 tunnel (ping6 from Iran to Kharej)..."
  if ping6 -c 3 fde8:b030:25cf::de02 | grep -q '3 received'; then
    echo "[✓] IPv6 tunnel is reachable."
  else
    echo "❌ IPv6 tunnel failed. Aborting."
    exit 1
  fi

  echo "[4] Setting up GRE6 on Iran server..."
  (
    ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote fde8:b030:25cf::de02 local fde8:b030:25cf::de01 2>/dev/null || true
    ip addr add 172.20.20.1/30 dev GRE6Tun_To_KH
    ip link set GRE6Tun_To_KH mtu 1436
    ip link set GRE6Tun_To_KH up
  ) & show_loader

  echo "[5] Setting up GRE6 on Kharej server..."
  (
    sshpass -p "$PASS_KHAREJ" ssh $USER_KHAREJ@$IP_KHAREJ '
      ip -6 tunnel add GRE6Tun_To_IR mode ip6gre remote fde8:b030:25cf::de01 local fde8:b030:25cf::de02 2>/dev/null || true
      ip addr add 172.20.20.2/30 dev GRE6Tun_To_IR
      ip link set GRE6Tun_To_IR mtu 1436
      ip link set GRE6Tun_To_IR up
    '
  ) & show_loader

  echo "[6] Testing GRE6 IPv4 tunnel (ping from Iran to Kharej)..."
  if ping -c 3 172.20.20.2 | grep -q '3 received'; then
    echo "[✓] GRE IPv4 tunnel is reachable."
  else
    echo "❌ GRE tunnel failed. Aborting."
    exit 1
  fi

  echo "[7] Enabling NAT & IP forwarding on Iran server..."
  (
    sysctl -w net.ipv4.ip_forward=1
    iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 172.20.20.1
    iptables -t nat -A PREROUTING -j DNAT --to-destination 172.20.20.2
    iptables -t nat -A POSTROUTING -j MASQUERADE
  ) & show_loader

  echo "\n✅ Tunnel setup completed successfully!"
  read -p "Press Enter to return to menu..."
}

function menu() {
  while true; do
    clear
    echo "========= GRE + 6to4 Tunnel Setup Script ========="
    echo "1. Automatic Configuration (Iran <-> Kharej)"
    echo "2. Exit"
    echo "=================================================="
    read -p "Select an option: " choice

    case $choice in
      1) setup_auto ;;
      2) exit ;;
      *) echo "Invalid option"; sleep 1 ;;
    esac
  done
}

menu

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

function validate_ssh() {
  echo "Checking SSH access to Kharej server..."
  while true; do
    if sshpass -p "$PASS_KHAREJ" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 $USER_KHAREJ@$IP_KHAREJ "echo connected" 2>/dev/null | grep -q connected; then
      break
    else
      echo "❌ Invalid username or password. Try again."
      read -p "Username: " USER_KHAREJ
      read -s -p "Password: " PASS_KHAREJ
      echo
    fi
  done
}

function restart_server() {
  echo "Rebooting system..."
  reboot
}

function setup_auto() {
  echo "[Auto Setup - GRE + 6to4 Tunnel]"
  read -p "Kharej Server IPv4: " IP_KHAREJ
  read -p "Iran Server IPv4 (local): " IP_IRAN
  read -p "Kharej Server SSH Username: " USER_KHAREJ
  read -s -p "Kharej Server SSH Password: " PASS_KHAREJ
  echo

  validate_ssh

  echo "[1] Setting up 6to4 tunnel on Iran server..."
  (
    ip tunnel add 6to4_To_KH mode sit remote $IP_KHAREJ local $IP_IRAN 2>/dev/null || true
    ip -6 addr add fde8:b030:25cf::de01/64 dev 6to4_To_KH 2>/dev/null || true
    ip link set 6to4_To_KH mtu 1480
    ip link set 6to4_To_KH up
  ) & show_loader

  echo "[2] Setting up 6to4 tunnel on Kharej server..."
  (
    sshpass -p "$PASS_KHAREJ" ssh -o StrictHostKeyChecking=no $USER_KHAREJ@$IP_KHAREJ '
      ip tunnel add 6to4_To_IR mode sit remote '"$IP_IRAN"' local '"$IP_KHAREJ"' 2>/dev/null || true
      ip -6 addr add fde8:b030:25cf::de02/64 dev 6to4_To_IR 2>/dev/null || true
      ip link set 6to4_To_IR mtu 1480
      ip link set 6to4_To_IR up
    '
  ) & show_loader

  echo "[3] Testing IPv6 connectivity..."
  if ping6 -c 3 fde8:b030:25cf::de02 | grep -q '3 received'; then
    echo "[✓] IPv6 connectivity verified."
  else
    echo "❌ IPv6 tunnel failed. Aborting."
    exit 1
  fi

  echo "[4] Setting up GRE6 tunnel on Iran server..."
  (
    ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote fde8:b030:25cf::de02 local fde8:b030:25cf::de01 2>/dev/null || true
    ip addr add 172.20.20.1/30 dev GRE6Tun_To_KH
    ip link set GRE6Tun_To_KH mtu 1436
    ip link set GRE6Tun_To_KH up
  ) & show_loader

  echo "[5] Setting up GRE6 tunnel on Kharej server..."
  (
    sshpass -p "$PASS_KHAREJ" ssh $USER_KHAREJ@$IP_KHAREJ '
      ip -6 tunnel add GRE6Tun_To_IR mode ip6gre remote fde8:b030:25cf::de01 local fde8:b030:25cf::de02 2>/dev/null || true
      ip addr add 172.20.20.2/30 dev GRE6Tun_To_IR
      ip link set GRE6Tun_To_IR mtu 1436
      ip link set GRE6Tun_To_IR up
    '
  ) & show_loader

  echo "[6] Testing GRE6 IPv4 tunnel..."
  if ping -c 3 172.20.20.2 | grep -q '3 received'; then
    echo "[✓] GRE tunnel is working."
  else
    echo "❌ GRE tunnel failed. Aborting."
    exit 1
  fi

  echo "[7] Enabling IP Forwarding and NAT..."
  (
    sysctl -w net.ipv4.ip_forward=1
    iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 172.20.20.1
    iptables -t nat -A PREROUTING -j DNAT --to-destination 172.20.20.2
    iptables -t nat -A POSTROUTING -j MASQUERADE
  ) & show_loader

  echo "\n✅ Tunnel established successfully."
  read -p "Press Enter to return to menu..."
}

function test_ping() {
  read -p "Ping direction (1 = Iran -> Kharej, 2 = Kharej -> Iran): " direction
  if [[ $direction == 1 ]]; then
    echo "Testing from Iran to Kharej..."
    ping -c 3 172.20.20.2 && echo "[✓] IPv4 OK" || echo "[✗] IPv4 Failed"
    ping6 -c 3 fde8:b030:25cf::de02 && echo "[✓] IPv6 OK" || echo "[✗] IPv6 Failed"
  elif [[ $direction == 2 ]]; then
    echo "Testing from Kharej to Iran..."
    read -p "Kharej Server IPv4: " IP_KHAREJ
    read -p "Username: " USER_KHAREJ
    read -s -p "Password: " PASS_KHAREJ
    echo
    sshpass -p "$PASS_KHAREJ" ssh -o StrictHostKeyChecking=no $USER_KHAREJ@$IP_KHAREJ '
      ping -c 3 172.20.20.1 && echo "[✓] IPv4 OK" || echo "[✗] IPv4 Failed"
      ping6 -c 3 fde8:b030:25cf::de01 && echo "[✓] IPv6 OK" || echo "[✗] IPv6 Failed"
    '
  else
    echo "Invalid option."
  fi
  read -p "Press Enter to return to menu..."
}

function menu() {
  while true; do
    clear
    echo "========= GRE + 6to4 Tunnel Setup Script ========="
    echo "1. Automatic Tunnel Setup (Iran to Kharej)"
    echo "2. Restart Server"
    echo "3. Ping Test"
    echo "4. Exit"
    echo "=================================================="
    read -p "Select an option: " choice

    case $choice in
      1) setup_auto ;;
      2) restart_server ;;
      3) test_ping ;;
      4) exit ;;
      *) echo "Invalid option"; sleep 1 ;;
    esac
  done
}

menu

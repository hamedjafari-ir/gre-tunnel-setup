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
    sshpass -p "$PASS_KHAREJ" ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -o StrictHostKeyChecking=no -o ConnectTimeout=5 $USER_KHAREJ@$IP_KHAREJ "echo connected" 2>/dev/null | grep -q connected
    if [ $? -eq 0 ]; then
      echo "[✓] SSH authentication successful."
      break
    else
      echo "❌ Invalid username or password. Try again."
      read -p "Kharej Server SSH Username: " USER_KHAREJ
      read -s -p "Kharej Server SSH Password: " PASS_KHAREJ
      echo
    fi
  done
}

function setup_auto() {
  echo "[Auto Setup - GRE + 6to4 Tunnel]"
  read -p "Kharej Server IPv4: " IP_KHAREJ
  read -p "Kharej Server SSH Username: " USER_KHAREJ
  read -s -p "Kharej Server SSH Password: " PASS_KHAREJ
  echo

  validate_ssh

  IP_IRAN=$(hostname -I | awk '{print $1}')
  echo "Detected Iran Server IPv4: $IP_IRAN"

  echo "[1] Setting up 6to4 tunnel on Iran server..."
  (
    ip tunnel add 6to4_To_KH mode sit remote $IP_KHAREJ local $IP_IRAN 2>/dev/null || true
    ip -6 addr add fde8:b030:25cf::de01/64 dev 6to4_To_KH 2>/dev/null || true
    ip link set 6to4_To_KH mtu 1480
    ip link set 6to4_To_KH up
  ) & show_loader

  echo "[2] Setting up 6to4 tunnel on Kharej server..."
  (
    sshpass -p "$PASS_KHAREJ" ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -o StrictHostKeyChecking=no $USER_KHAREJ@$IP_KHAREJ "
      ip tunnel add 6to4_To_IR mode sit remote $IP_IRAN local $IP_KHAREJ 2>/dev/null || true
      ip -6 addr add fde8:b030:25cf::de02/64 dev 6to4_To_IR 2>/dev/null || true
      ip link set 6to4_To_IR mtu 1480
      ip link set 6to4_To_IR up"
  ) & show_loader

  echo "[3] Testing IPv6 tunnel from Iran to Kharej..."
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
    sshpass -p "$PASS_KHAREJ" ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -o StrictHostKeyChecking=no $USER_KHAREJ@$IP_KHAREJ "
      ip -6 tunnel add GRE6Tun_To_IR mode ip6gre remote fde8:b030:25cf::de01 local fde8:b030:25cf::de02 2>/dev/null || true
      ip addr add 172.20.20.2/30 dev GRE6Tun_To_IR
      ip link set GRE6Tun_To_IR mtu 1436
      ip link set GRE6Tun_To_IR up"
  ) & show_loader

  echo "[6] Testing GRE IPv4 tunnel..."
  if ping -c 3 172.20.20.2 | grep -q '3 received'; then
    echo "[✓] GRE tunnel is working."
  else
    echo "❌ GRE tunnel failed. Aborting."
    exit 1
  fi

  echo "[7] Enabling NAT and IP forwarding on Iran server..."
  (
    sysctl -w net.ipv4.ip_forward=1
    iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 172.20.20.1
    iptables -t nat -A PREROUTING -j DNAT --to-destination 172.20.20.2
    iptables -t nat -A POSTROUTING -j MASQUERADE
  ) & show_loader

  echo -e "\n✅ Tunnel has been successfully established."
  read -p "Press Enter to return to menu..."
}

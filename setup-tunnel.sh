#!/bin/bash
# ---------------------------------------------------------------
# Script Name : setup-tunnel.sh
# Description : Auto/manual setup of 6to4 + GRE IPv6 tunnel with self-update
# Author      : Hamed Jafari
# GitHub      : https://github.com/hamedjafari-ir/gre-tunnel-setup
# Date        : 2025-06-15
# License     : MIT
# ---------------------------------------------------------------
set -e

SCRIPT_URL="https://raw.githubusercontent.com/hamedjafari-ir/gre-tunnel-setup/main/setup-tunnel.sh"
INSTALL_PATH="/usr/local/bin/tunnel"
STATUS_FILE="/tmp/tunnel_status"

function self_update() {
  if [[ $0 != "$INSTALL_PATH" ]]; then
    echo "Installing tunnel command..."
    curl -Ls "$SCRIPT_URL" -o "$INSTALL_PATH"
    chmod +x "$INSTALL_PATH"
    echo "You can now run this script anytime using: tunnel"
    sleep 2
    exec "$INSTALL_PATH"
    exit
  else
    echo "Checking for script updates..."
    TMP_SCRIPT=$(mktemp)
    if ! curl -m 10 -fsSL "$SCRIPT_URL" -o "$TMP_SCRIPT"; then
      echo "[✗] Failed to download the script from GitHub."
      echo "Check your internet connection or the GitHub URL."
      sleep 3
      return
    fi
    if ! cmp -s "$TMP_SCRIPT" "$INSTALL_PATH"; then
      echo "Updating script..."
      mv "$TMP_SCRIPT" "$INSTALL_PATH"
      chmod +x "$INSTALL_PATH"
      echo "Script updated. Restarting..."
      exec "$INSTALL_PATH"
    else
      rm "$TMP_SCRIPT"
      echo "You already have the latest version."
    fi
  fi
}

function show_loader() {
  local pid=$!
  local spin='-/|\\'
  local i=0
  while kill -0 $pid 2>/dev/null; do
    i=$(( (i+1) %4 ))
    printf "\r[%c] Working..." "${spin:$i:1}"
    sleep 0.2
  done
  echo -e "\r[✓] Done         "
}

function check_tools() {
  echo "[+] Checking required tools..."
  for tool in curl ip ssh sshpass ping6 ping iptables; do
    if ! command -v $tool &>/dev/null; then
      echo "[!] Missing: $tool. Installing..."
      apt-get update -y && apt-get install -y $tool
    fi
  done
}

function validate_ssh() {
  local host=$1
  local user=$2
  local pass=$3
  echo "[+] Validating SSH to $host..."
  if sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 $user@$host "echo OK" &>/dev/null; then
    echo "[✓] SSH connection to $host successful."
    return 0
  else
    echo "[✗] SSH connection to $host failed. Invalid credentials."
    return 1
  fi
}

function check_tunnel_status() {
  echo "[+] Checking GRE6 tunnel connectivity..."
  if ip addr | grep -q "172.20.20.1"; then
    if ping -c 2 172.20.20.2 &>/dev/null; then
      echo "[✓] GRE6 tunnel is up."
    else
      echo "[✗] GRE6 interface found but ping failed."
    fi
  else
    echo "[!] GRE6 interface not found. Setup may not be complete."
  fi
}

function test_target_reachability() {
  read -p "Enter target IPv4 to check if filtered: " target_ip
  echo "[+] Pinging $target_ip..."
  if ping -c 3 $target_ip &>/dev/null; then
    echo "[✓] $target_ip is reachable."
  else
    echo "[✗] $target_ip is filtered or unreachable."
  fi
}

function setup_manual() {
  echo "Manual mode selected. Please enter commands manually on both servers."
}

function setup_auto() {
  echo "[+] Starting auto setup..."
  read -p "Remote Server IPv4: " REMOTE_IPV4
  read -p "Local Server IPv4: " LOCAL_IPV4
  read -p "Remote SSH User: " REMOTE_USER
  read -s -p "Remote SSH Password: " REMOTE_PASS
  echo

  validate_ssh "$REMOTE_IPV4" "$REMOTE_USER" "$REMOTE_PASS" || setup_auto

  echo "[+] Setting up 6to4 tunnel on local (Iran) server..."
  ip tunnel del 6to4_To_KH 2>/dev/null || true
  ip tunnel add 6to4_To_KH mode sit remote $REMOTE_IPV4 local $LOCAL_IPV4
  ip -6 addr add fde8:b030:25cf::de01/64 dev 6to4_To_KH
  ip link set 6to4_To_KH mtu 1480
  ip link set 6to4_To_KH up

  echo "[+] Configuring remote server..."
  sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_IPV4 "
    ip tunnel del 6to4_To_IR 2>/dev/null || true
    ip tunnel add 6to4_To_IR mode sit remote $LOCAL_IPV4 local $REMOTE_IPV4 && 
    ip -6 addr add fde8:b030:25cf::de02/64 dev 6to4_To_IR && 
    ip link set 6to4_To_IR mtu 1480 && 
    ip link set 6to4_To_IR up"

  echo "[+] Testing IPv6 connectivity..."
  if ping6 -c 3 fde8:b030:25cf::de02 &>/dev/null; then
    echo "[✓] IPv6 tunnel active."
  else
    echo "[✗] IPv6 ping failed. Aborting."
    echo "disconnected" > "$STATUS_FILE"
    return
  fi

  echo "[+] Configuring GRE6 tunnel..."
  ip -6 tunnel del GRE6Tun_To_KH 2>/dev/null || true
  ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote fde8:b030:25cf::de02 local fde8:b030:25cf::de01
  ip addr add 172.20.20.1/30 dev GRE6Tun_To_KH
  ip link set GRE6Tun_To_KH mtu 1436
  ip link set GRE6Tun_To_KH up

  sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_IPV4 "
    ip -6 tunnel del GRE6Tun_To_IR 2>/dev/null || true
    ip -6 tunnel add GRE6Tun_To_IR mode ip6gre remote fde8:b030:25cf::de01 local fde8:b030:25cf::de02 && 
    ip addr add 172.20.20.2/30 dev GRE6Tun_To_IR && 
    ip link set GRE6Tun_To_IR mtu 1436 && 
    ip link set GRE6Tun_To_IR up"

  echo "[+] Pinging GRE endpoint..."
  if ping -c 3 172.20.20.2 &>/dev/null; then
    echo "[✓] GRE tunnel active."
    echo "connected" > "$STATUS_FILE"
  else
    echo "[✗] GRE tunnel failed."
    echo "disconnected" > "$STATUS_FILE"
    return
  fi

  echo "[+] Finalizing setup with IP forwarding..."
  sysctl -w net.ipv4.ip_forward=1
  iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 172.20.20.1
  iptables -t nat -A PREROUTING -j DNAT --to-destination 172.20.20.2
  iptables -t nat -A POSTROUTING -j MASQUERADE

  echo "[✓] Tunnel setup complete and verified."
}

function restart_server() {
  echo "[!] Server will restart in 5 seconds..."
  sleep 5
  reboot
}

function about_script() {
  echo "This script sets up a dual 6to4 and GRE6 IPv6 tunnel between two servers."
  echo "Created by Hamed Jafari - 2025"
}

function test_ping() {
  if [[ ! -f "$STATUS_FILE" || $(cat $STATUS_FILE) != "connected" ]]; then
    echo "[!] Tunnel not active. Please run auto setup first."
    return
  fi
  echo "[+] Ping Test Menu"
  echo "1) From Iran to Foreign"
  echo "2) From Foreign to Iran"
  read -p "Choose option: " option
  if [[ $option == "1" ]]; then
    echo "Testing from Iran (fde8:b030:25cf::de01 -> fde8:b030:25cf::de02, 172.20.20.1 -> 172.20.20.2)"
    ping6 -c 3 fde8:b030:25cf::de02 && ping -c 3 172.20.20.2
  elif [[ $option == "2" ]]; then
    echo "Testing from Foreign (fde8:b030:25cf::de02 -> fde8:b030:25cf::de01, 172.20.20.2 -> 172.20.20.1)"
    ping6 -c 3 fde8:b030:25cf::de01 && ping -c 3 172.20.20.1
  fi
}

function menu() {
  while true; do
    STATUS=""
    if [[ -f "$STATUS_FILE" && $(cat $STATUS_FILE) == "connected" ]]; then
      STATUS=" [CONNECTED]"
    fi
    echo -e "\n========= GRE6 Tunnel Setup Menu$STATUS ========="
    echo "1) Auto Setup Tunnel"
    echo "2) Manual Setup"
    echo "3) Test Ping"
    echo "4) Restart Server"
    echo "5) About This Script"
    echo "6) Check GRE Tunnel Status"
    echo "7) Check Target IP Reachability"
    echo "8) Exit"
    read -p "Choose an option: " CHOICE
    case $CHOICE in
      1) setup_auto;;
      2) setup_manual;;
      3) test_ping;;
      4) restart_server;;
      5) about_script;;
      6) check_tunnel_status;;
      7) test_target_reachability;;
      8) exit 0;;
      *) echo "Invalid option.";;
    esac
  done
}

self_update
check_tools
menu

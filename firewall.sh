#!/usr/bin/sudo /bin/bash

IPT=/sbin/iptables
INTERFACE="wlan"
LOCAL_NET=$(ip addr show | grep $INTERFACE | grep inet | awk '{print $2}')
PPTP_PORT=1723
PPTP_IP=$(netstat -nat | grep :$PPTP_PORT | grep ESTABLISHED | awk '{print $5}' | sed 's/:.*//')

echo "Local network: $LOCAL_NET"
echo "PPTP server: $PPTP_IP"

function clear_fw_filter {
  $IPT --delete-chain
  $IPT --flush
  $IPT --policy INPUT ACCEPT
  $IPT --policy FORWARD ACCEPT
  $IPT --policy OUTPUT ACCEPT
}

function clear_fw_nat {
  $IPT --table nat --delete-chain
  $IPT --table nat --flush
  $IPT --table nat --policy PREROUTING ACCEPT
  $IPT --table nat --policy INPUT ACCEPT
  $IPT --table nat --policy OUTPUT ACCEPT
  $IPT --table nat --policy POSTROUTING ACCEPT
}

function clear_fw_mangle {
  $IPT --table mangle --delete-chain
  $IPT --table mangle --flush
  $IPT --table mangle --policy PREROUTING ACCEPT
  $IPT --table mangle --policy INPUT ACCEPT
  $IPT --table mangle --policy FORWARD ACCEPT
  $IPT --table mangle --policy OUTPUT ACCEPT
  $IPT --table mangle --policy POSTROUTING ACCEPT
}

function clear_fw_raw {
  $IPT --table raw --delete-chain
  $IPT --table raw --flush
  $IPT --table raw --policy PREROUTING ACCEPT
  $IPT --table raw --policy OUTPUT ACCEPT
}

function clear_fw {
  echo "Clearing iptable rules . . ."
  clear_fw_filter
  clear_fw_nat
  clear_fw_mangle
  clear_fw_raw
}

clear_fw

echo "Enforcing iptables output rules . . ."
$IPT --append OUTPUT --out-interface $INTERFACE+ --destination $LOCAL_NET --jump ACCEPT
$IPT --append OUTPUT --out-interface $INTERFACE+ --destination $PPTP_IP --jump ACCEPT
$IPT --append OUTPUT --out-interface $INTERFACE+ --protocol tcp --dport $PPTP_PORT --jump ACCEPT
$IPT --append OUTPUT --out-interface $INTERFACE+ --jump DROP

echo "Our PPTP IP: $(curl -s http://ipecho.net/plain)"

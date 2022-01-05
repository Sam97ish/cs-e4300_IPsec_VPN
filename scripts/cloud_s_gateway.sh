#!/usr/bin/env bash

## Traffic going to the internet
route add default gw 172.30.30.1

## Currently no NAT
iptables -t nat -A POSTROUTING -o enp0s8 -j MASQUERADE

## Save the iptables rules
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

## IPsec secrets
# A to Cloud
echo 172.30.30.30 172.16.16.16 : PSK \"remAnDwypYwXX10f69w7LTCYGdF3/rAZBC98kthmcBAlnUZs9r0Gn+odpRSkNHeNVlgWnzl3wztuu/s5htLdMBAA==\" >> /etc/ipsec.secrets
# B to Cloud
echo 172.30.30.30 172.18.18.18 : PSK \"0nPfzPJTzB6xJA+7TmtTeoZkAREKvHQ/Rb4vs9YWkh7C6fF30MJ7zcrOT1GilPKrtArg616Pm1wT7cVfSmGegnQ==\" >> /etc/ipsec.secrets

## IPsec conf
cat > /etc/ipsec.conf <<EOL
config setup
        charondebug=all
        uniqueids=yes
        strictcrlpolicy=no

conn cloud-to-gateway-a
        authby=secret
        type=tunnel
        leftfirewall=yes
        left=172.30.30.30
        leftsubnet=10.0.0.0/24
        right=172.16.16.16
        keyexchange=ikev2
        ike=aes256-sha2_256-modp1024!
        esp=aes256-sha2_256!
        keyingtries=0
        ikelifetime=1h
        lifetime=8h
        dpddelay=30
        dpdtimeout=120
        dpdaction=restart
        auto=start
        
conn cloud-to-gateway-b
        authby=secret
        type=tunnel
        leftfirewall=yes
        left=172.30.30.30
        leftsubnet=10.0.0.0/24
        right=172.18.18.18
        keyexchange=ikev2
        ike=aes256-sha2_256-modp1024!
        esp=aes256-sha2_256!
        keyingtries=0
        ikelifetime=1h
        lifetime=8h
        dpddelay=30
        dpdtimeout=120
        dpdaction=restart
        auto=start
EOL

## restart IPsec
ipsec restart

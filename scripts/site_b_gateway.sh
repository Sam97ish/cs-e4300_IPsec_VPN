#!/usr/bin/env bash

## NAT traffic going to the internet
route add default gw 172.18.18.1
iptables -t nat -A POSTROUTING -o enp0s8 -j MASQUERADE

## Save the iptables rules
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

## IPsec secrets
echo 172.18.18.18 172.30.30.30 : PSK \"0nPfzPJTzB6xJA+7TmtTeoZkAREKvHQ/Rb4vs9YWkh7C6fF30MJ7zcrOT1GilPKrtArg616Pm1wT7cVfSmGegnQ==\" >> /etc/ipsec.secrets

## IPsec conf
cat > /etc/ipsec.conf <<EOL
config setup
        charondebug=all
        uniqueids=yes
        strictcrlpolicy=no

conn gateway-b-to-cloud-server
        authby=secret
        type=tunnel
        left=172.18.18.18
        right=172.30.30.30
        rightsubnet=10.0.0.0/24
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

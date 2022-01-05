#!/usr/bin/env bash

## NAT traffic going to the internet
route add default gw 172.16.16.1
iptables -t nat -A POSTROUTING -o enp0s8 -j MASQUERADE

## Save the iptables rules
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

## IPsec secrets
echo 172.16.16.16 172.30.30.30 : PSK \"remAnDwypYwXX10f69w7LTCYGdF3/rAZBC98kthmcBAlnUZs9r0Gn+odpRSkNHeNVlgWnzl3wztuu/s5htLdMBAA==\" >> /etc/ipsec.secrets

## IPsec conf
cat > /etc/ipsec.conf <<EOL
config setup
        charondebug=all
        uniqueids=yes
        strictcrlpolicy=no

conn gateway-a-to-cloud-server
        authby=secret
        type=tunnel
        left=172.16.16.16
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

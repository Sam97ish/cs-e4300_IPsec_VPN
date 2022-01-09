#!/usr/bin/env bash

## Traffic going to the internet
route add default gw 172.30.30.1

## NAT
iptables --in-interface enp0s8 --append PREROUTING --table nat --protocol tcp --source 172.16.16.16 --destination 172.30.30.30 --dport 8080 --jump DNAT --to-destination 10.0.0.2:8080

iptables --in-interface enp0s8 --append PREROUTING --table nat --protocol tcp --source 172.18.18.18 --destination 172.30.30.30 --dport 8080 --jump DNAT --to-destination 10.0.0.3:8080

# No need for this, masquerade already does this.
#iptables --append POSTROUTING --table nat --protocol tcp --destination 172.16.16.16 --jump SNAT --to-source 172.30.30.30

iptables -t nat -A POSTROUTING -o enp0s8 -j MASQUERADE

#iptables -t nat -I POSTROUTING -m policy --dir out --pol ipsec -j ACCEPT

## Firewall rules
iptables -A INPUT ! -s 10.0.0.0/24 -d 10.0.0.1 -j REJECT # Drop everything going to gateway-s that is coming from the private network.


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
        leftsubnet=172.30.30.30/32
        right=172.16.16.16
        rightsubnet=172.16.16.16/32
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
        leftsubnet=172.30.30.30/32        
        right=172.18.18.18
        rightsubnet=172.18.18.18/32
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

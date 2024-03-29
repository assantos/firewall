#!/bin/bash
# Configure iptables firewall

# Limit PATH
PATH="/sbin:/usr/sbin:/bin:/usr/bin"

# iptables configuration
firewall_start() {

###Bloqueia tudo
iptables -P INPUT  DROP
iptables -P OUTPUT  DROP
iptables -P FORWARD  DROP

###Habilita o NAT
iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE 

##### Regras acesso a VM Security #####

### Libera conexoes ja estabelecidas
iptables -t filter -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -t filter -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -t filter -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

### Libera acesso SSH ao firewall
iptables -A INPUT -p tcp --syn --dport 22 -j ACCEPT

### Libera ICMP para o firewall
iptables -t filter -A OUTPUT -p icmp -s 0/0 -d 0/0 -j ACCEPT
iptables -t filter -A INPUT -p icmp --icmp-type 8 -s 172.16.1.0/24 -d 0/0 -j ACCEPT
iptables -t filter -A INPUT -p icmp --icmp-type 8 -s 192.168.20.0/24 -d 0/0 -j ACCEPT

### Libera DNS para o firewall
iptables -t filter -A OUTPUT -p udp -d 0/0 --dport 53 -j ACCEPT

### Libera HTTP e HTTPS para o firewall
iptables -t filter -A OUTPUT -p tcp -m multiport -d 0/0 --dport 80,443 -j ACCEPT

##### Regras para a Rede 172.16.1.0/24 #####

###Libera ICMP a partir da rede
iptables -t filter -A FORWARD -p icmp --icmp-type 0 -s 172.16.1.0/24 -d 0/0 -j ACCEPT
iptables -t filter -A FORWARD -p icmp --icmp-type 8 -s 172.16.1.0/24 -d 0/0 -j ACCEPT

### Libera consulta DNS a partir da LAN
iptables -A FORWARD -p udp -s 172.16.1.0/24 -d 0/0 --dport 53 -j ACCEPT

### Libera consulta HTTP e HTTPS a partir da LAN 
iptables -A FORWARD -p tcp -m multiport -s 172.16.1.0/24 -d 0/0 --dport 80,443 -j ACCEPT

### Redirecionamento
#iptables -t nat -A PREROUTING -p tcp -s 0/0 -d 192.168.10.X --dport 2210 -j DNAT --to 172.16.1.100:22 
#iptables -t filter -A FORWARD -p tcp -s 0/0 -d 172.16.1.100 --dport 22 -j ACCEPT

}

# clear iptables configuration
firewall_stop() {
###Limpa as tabelas
iptables -t filter -F
iptables -t mangle -F
iptables -t nat -F
}

# execute action
case "$1" in
  start|restart)
    echo "Starting firewall"
    firewall_stop
    firewall_start
    ;;
  stop)
    echo "Stopping firewall"
    firewall_stop
    ;;
esac

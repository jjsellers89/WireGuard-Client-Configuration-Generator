#!/bin/bash

project=WG_`date +%Y%m%d%H%M%S`
echo "
[-] Please make sure WireGuard is installed before proceeding.
"

initial_setup () {
	read -p "[+] What is your WireGuard server IP? " endpoint_ip
	read -p "[+] What is your WireGuard server listening port? " endpoint_port
	read -p "[+] What VPN subnet would you like to use? (Example: 10.0.0.0) " subnet

	subnet_function () {
		read -p "[+] What CIDR would you like to use? (Choose value between 24 and 30) " cidr 
		case $cidr in
			24)
			max_clients=254
			;;
			25)
			max_clients=126
			;;
			26)
			max_clients=62
			;;
			27)
			max_clients=30
			;;
			28)
			max_clients=14
			;;
			29)
			max_clients=6
			;;
			30)
			max_clients=2
			;;
			*)
			echo "[-] Warning: Please choose CIDR value between 24 and 30 "
			subnet_function
			;;
		esac
	}
	subnet_function

	client_total () {
		read -p "[+] How many client configurations would you like to generate? " client_total

		if [ $client_total -ge $max_clients ]
		then
			echo -e "[-] Warning: Please choose a number greater than 1 and less than $max_clients"
			client_total
		fi
	} 
	client_total

	#Confirm everything in initial setup
	confirm_function () {
		clear
		echo -e "Please confirm: \n
		WireGuard Server IP: $endpoint_ip
		WireGuard Server Listening Port: $endpoint_port
		VPN tunnel IP and CIDR: $subnet/$cidr
		Number of VPN client configurations: $client_total\n"
		read -p "Is this information correct? (Answer [Y]es or [N]o) " confirm_answer

		if [ $confirm_answer = "Y" ] || [ $confirm_answer = "y" ]
			then
				return
		elif [ $confirm_answer = "N" ] || [ $confirm_answer = "n" ]
			then
				clear
				initial_setup
		else
			confirm_function
		fi
	}
	confirm_function
}

initial_setup

echo Creating `pwd`/$project
mkdir -p ./$project/{confs,keys_server,keys_clients}

################
# GENERATE KEYS
################

wg genkey | tee `pwd`/$project/keys_server/private_server.key | wg pubkey > `pwd`/$project/keys_server/public_server.key

for i in $(seq 1 $client_total); do 
    wg genkey | tee `pwd`/$project/keys_clients/private_client$i.key | wg pubkey > `pwd`/$project/keys_clients/public_client$i.key
done

#############################
# GENERATE CONFIGS - CLIENTS
#############################

for i in $(seq 1 $client_total); do
    server_public=`cat $(pwd)/$project/keys_server/public_server.key`
    client_private=`cat $(pwd)/$project/keys_clients/private_client$i.key`
    client_public=`cat $(pwd)/$project/keys_clients/public_client$i.key`
    subnet_3octets=`echo $subnet | cut -d "." -f 1-3`
    echo "
[Interface]
PrivateKey = $client_private
Address = $subnet_3octets.$i/$cidr

[Peer]
PublicKey = $server_public
AllowedIPs = $subnet_3octets.0/$cidr
Endpoint = $endpoint_ip:$endpoint_port
PersistentKeepalive = 25
    " > `pwd`/$project/confs/client$i.conf
done

############################
# GENERATE CONFIGS - SERVER
############################

server_private=`cat $(pwd)/$project/keys_server/private_server.key`
echo "
[Interface]
ListenPort = $endpoint_port
PrivateKey = $server_private
Address = $subnet_3octets.$max_clients/$cidr
PostUp = echo 1 > /proc/sys/net/ipv4/ip_forward; iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
PostDown = echo 0 > /proc/sys/net/ipv4/ip_forward; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
" > `pwd`/$project/confs/wg-server.conf

for i in $(seq 1 $client_total); do
	client_public=`cat $(pwd)/$project/keys_clients/public_client$i.key`
	echo "
[Peer] # Client $i
PublicKey = $client_public
AllowedIPs = $subnet_3octets.$i/32
" >> `pwd`/$project/confs/wg-server.conf
done

############
# Complete!
############

echo "
[+] Complete: All WireGuard keys and configurations have been generated to `pwd`/$project/
"

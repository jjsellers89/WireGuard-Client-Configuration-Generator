# WireGuard Client Configuration Generator

- This script assumes you already have WireGuard installed on your workstation, as it will require WireGuard to generate public/private keys.
- This script also assumes you will be using a Linux OS as the WireGuard server, as it will utilize iptables on the server configuration.
- Lastly, this script does not assume you require DNS, MTU, preshared keys or AllowedIPs = 0.0.0.0/0 entries into the configurations. (With a minor modification to the script, you may add these in without issue)

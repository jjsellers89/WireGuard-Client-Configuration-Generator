# WireGuard Client Configuration Generator

- This script assumes you've installed WireGuard already (script requires *wg* to generate public/private keys).
- This script also assumes you're WireGuard server has iptables installed (PostUp/PostDown iptables rules will be included on the server configuration).
- Lastly, this script assumes you do *NOT* require DNS, MTU, preshared keys or AllowedIPs = 0.0.0.0/0 entries into the configurations. (With a minor modification to the script, you may add these in without issue)

Recommendation: 
- Install qrencode for convenience. ```qrencode -t ansiutf8 < client1.conf``` This will allow WireGuard client applications to scan QR codes instead of manually typing in WireGuard parameters (Very useful for Android/iOS clients) 

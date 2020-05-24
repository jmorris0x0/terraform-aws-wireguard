[Interface]
PrivateKey = ${wireguard_client_private_key}
ListenPort = ${wg_server_port}
Address = 10.20.40.2/24 
DNS = 1.1.1.1

[Peer]
PublicKey = ${wireguard_server_public_key}
Endpoint = ${server_ip}:${wg_server_port}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = ${persistent_keepalive}

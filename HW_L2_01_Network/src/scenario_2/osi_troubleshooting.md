# OSI Model & Troubleshooting

## 1. The 7 OSI Layers

1. **Layer 1 - Physical**: Raw bits over the wire/radio; cables, NICs, signal.
2. **Layer 2 - Data Link**: Frames between directly connected nodes; MAC addressing, switching.
3. **Layer 3 - Network**: Routing between networks; IP addressing, logical paths.
4. **Layer 4 - Transport**: End-to-end delivery; TCP/UDP, ports, flow control.
5. **Layer 5 - Session**: Establishes/maintains sessions between apps.
6. **Layer 6 - Presentation**: Data encoding, encryption, translation.
7. **Layer 7 - Application**: User-facing protocols (HTTP, DNS, SSH).

## 2. Troubleshooting "User can't reach the website" (Layer 1 to 7)

- **L1 Physical**: Is the cable plugged in / WiFi associated? Link LED on?
- **L2 Data Link**: Is the MAC address valid? Is the switch port UP? ARP resolving the gateway MAC?
- **L3 Network**: Does the host have a valid IP/subnet? Is there a route to the gateway/internet? Does the DNS name resolve? Can you ping the website IP?
- **L4 Transport**: Is the web server's port 80/443 reachable? Are TCP connections opening or timing out?
- **L5 Session**: Is the TCP session being established and maintained? Any resets mid-stream?
- **L6 Presentation**: Is TLS/encryption negotiating correctly? Certificates valid?
- **L7 Application**: Is the web server running and responding? HTTP status codes (404/500)?

## 3. One Linux Tool Per Layer

| Layer | Tool/Command |
|-------|--------------|
| L1 Physical | `ethtool eth0` (link/speed), `ip link` |
| L2 Data Link | `ip neigh` (ARP table), `bridge link` |
| L3 Network | `ping`, `ip route`, `traceroute`, `dig` |
| L4 Transport | `ss -tuln`, `netstat -tuln`, `nc -zv host port` |
| L5 Session | `ss -tn state established` |
| L6 Presentation | `openssl s_client -connect host:443` |
| L7 Application | `curl -v http://host/`, `systemctl status nginx` |

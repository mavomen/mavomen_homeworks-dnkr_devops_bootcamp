# Troubleshooting: "user cannot reach example.com"

step-by-step from the bottom of the stack up. run in order, stop when
something fails - that's your layer.

## 1. physical / link layer

```bash
ip link show              # is the interface UP?
nmcli device status       # wifi/eth connected?
```
- interface DOWN / no carrier -> cable, wifi off, driver issue
- fix: reconnect wifi, check cable, `sudo ip link set wlp7s0 up`

## 2. ip configuration

```bash
ip addr show wlp7s0       # do we have an IP at all?
ip route show             # is there a default route?
ping -c 3 192.168.1.1     # can we reach the gateway?
```
- no IP -> DHCP problem: `sudo dhclient -v wlp7s0` or reconnect
- no default route -> wrong network config
- gateway unreachable -> you're on the wrong network or AP is dead

## 3. dns resolution

```bash
cat /etc/resolv.conf
dig example.com                    # does it resolve?
dig example.com @8.8.8.8           # try another resolver
ping -c 2 93.184.216.34            # bypass dns entirely (example.com ip)
```
- dig fails but ping by IP works -> DNS is broken
- fix: switch resolver (`resolvectl dns wlp7s0 8.8.8.8`), restart
  systemd-resolved, or fix /etc/resolv.conf
- dig resolves but wrong IP -> poisoned hosts entry? check `/etc/hosts`

## 4. routing / path

```bash
traceroute example.com    # where does the path die?
mtr -r -c 20 example.com  # live loss/latency per hop
```
- stars after hop 1-2 -> your ISP/LAN problem
- stars only near the end -> target or its provider

## 5. firewall

```bash
sudo iptables -L -n | head        # local rules blocking?
curl -v --connect-timeout 5 https://example.com
```
- "connection timed out" but traceroute reaches the target ->
  something filters port 443 (local firewall, corporate proxy, ISP)
- fix: adjust rules (`ufw status`, iptables), check proxy env vars

## 6. application layer

```bash
curl -vI https://example.com      # full handshake + response
curl -sI http://example.com       # try plain http too
```
- TLS errors -> cert expired / clock skew (`timedatectl`)
- 5xx responses -> server-side problem, nothing to fix locally
- works with curl but not browser -> browser proxy/cache/DNS-over-HTTPS issue

## quick reference: symptom -> likely cause

| symptom | probable root cause | solution |
|---|---|---|
| no IP address | DHCP failure | renew lease / reconnect |
| IP ok, gateway unreachable | wrong vlan/wifi, AP down | rejoin correct network |
| ping IP ok, name fails | DNS down/misconfigured | change resolver, fix resolv.conf |
| traceroute dies at hop 1 | local router | reboot router |
| traceroute dies mid-path | ISP outage | wait / contact ISP |
| timeout on 443 only | firewall/proxy filtering | open port, fix proxy vars |
| TLS/cert errors | clock skew or expired cert | sync time (ntp), renew cert |
| 502/503 from server | backend down | server side - check service |

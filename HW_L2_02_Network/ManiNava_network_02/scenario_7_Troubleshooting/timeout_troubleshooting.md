# Troubleshooting scenario: "SSH connection to server times out"

## 1. what can cause the timeout

| # | cause | typical symptom |
|---|-------|-----------------|
| 1 | firewall silently dropping packets (server or middle) | connect phase hangs -> `Connection timed out` |
| 2 | wrong ip or wrong port (sshd moved to e.g. 2222) | same as above, or refused |
| 3 | routing problem / no path to host | hangs or "no route to host" |
| 4 | server down (or sshd not running) | refused if up-but-no-sshd, timeout if fully down |
| 5 | dns resolving to wrong/dead ip | hangs on the wrong target |
| 6 | tcp connects but service is hung (behind LB/proxy) | `Connection timed out during banner exchange` |

## 2. diagnostic command per cause

```bash
# is anything listening there at all? (refused vs timeout tells a lot)
nc -zv -w 5 server 22

# force a bounded attempt with verbose output
timeout 5 ssh -v user@server

# resolve first - is dns pointing where you expect?
dig +short server

# path check
traceroute server
ping -c 3 server            # icmp may be blocked even when ssh works!

# from the server console (if you have one): is sshd alive?
systemctl status sshd && ss -tlnp | grep sshd
```

## 3. solutions

- firewall drop -> open port (`ufw allow 2222/tcp`, security group rule)
- wrong port -> find real port: `ss -tlnp | grep sshd`, update client config
- routing -> fix default route / vpn split-tunnel config
- sshd dead -> restart via console/rescue: `systemctl restart sshd`
- dns wrong -> fix the record or use `/etc/hosts` temporarily
- hung service behind proxy -> restart backend, check LB health checks
- prevention: keep `ConnectTimeout`/`ServerAliveInterval` in ~/.ssh/config,
  run fail2ban + monitoring on the server

## 4. simulation script (timeout_test.sh)

ran on my machine - note: my traffic goes through a local tun proxy
(singbox), so even the "blackhole" ip accepts tcp and then hangs at the
banner - which nicely demonstrates cause #6:

```
== 1. classic timeout: non-routable ip ==
$ timeout 5 ssh -v user@10.255.255.1
debug1: Connecting to 10.255.255.1 [10.255.255.1] port 22.
...
Connection timed out during banner exchange

== 2. port closed vs filtered: nothing listening on localhost:2222 ==
$ nc -zv -w 3 localhost 2222
nc: connect to localhost (127.0.0.1) port 2222 (tcp) failed: Connection refused
^ "refused" = host up, nothing listening (cause #4 variant)
  vs "timed out" = packets dropped somewhere (cause #1/#3)

== 3. hung service: tcp accepts but never speaks ssh ==
$ nc -l 2229 &   # fake server that accepts but sends nothing
$ timeout 5 ssh -o ConnectTimeout=4 localhost -p 2229
Connection timed out during banner exchange
```

key takeaway: distinguish **connection refused** (reachable host, closed
port) from **timeout** (packets dropped or service hung) - they point to
completely different fixes.

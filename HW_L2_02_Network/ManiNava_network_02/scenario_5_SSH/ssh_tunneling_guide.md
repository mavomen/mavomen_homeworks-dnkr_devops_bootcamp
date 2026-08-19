# SSH Tunneling / Port Forwarding

SSH can carry arbitrary TCP traffic through an encrypted SSH connection.
Three directions: local (-L), remote (-R), dynamic (-D).

## 1. Local Port Forwarding (`-L`)

```bash
ssh -L 8080:localhost:80 user@server
```

"open my local port 8080; everything sent there comes out on the **server's**
side as a connection to localhost:80".

flow: app -> localhost:8080 -> [ssh tunnel] -> server -> server-local:80

useful flags: `-N` (no shell, just forward) and `-f` (background):
`ssh -NfL 8080:localhost:80 user@server`

## 2. Remote Port Forwarding (`-R`)

The reverse direction:

```bash
ssh -R 9000:localhost:3000 user@server
```

"server, open YOUR port 9000; connections to it come back through the tunnel
to MY machine's port 3000".

flow: someone -> server:9000 -> [ssh tunnel] -> my laptop -> localhost:3000

needs `GatewayPorts yes` in the server's sshd_config if you want it
reachable from other hosts (by default it binds to 127.0.0.1 on the server).

## 3. Dynamic Port Forwarding - SOCKS proxy (`-D`)

```bash
ssh -D 1080 -N user@server
```

No single target port - this creates a SOCKS5 proxy on local port 1080.
The client decides per-connection where to go, based on the destination each
app asks for. Point the browser at socks5://localhost:1080 and all its
traffic exits from the server.

## 4. Real use cases

| type | use case |
|------|----------|
| `-L` | reach an internal admin UI (Grafana on :3000) that only listens on the DB server's loopback, without exposing it: `ssh -NfL 3000:localhost:3000 admin@db01` |
| `-L` | connect a local DB GUI to a production postgres: `ssh -NfL 5433:db.internal:5432 jump@bastion` |
| `-R` | demo a locally developed webapp (:3000) to a teammate via a public VPS: `ssh -NR 9000:localhost:3000 me@vps` -> they open vps:9000 |
| `-R` | temporary reverse shell-style access to a device behind NAT |
| `-D` | quick personal encrypted proxy when on untrusted hotel/cafe wifi |

## notes

- all three are just TCP over SSH -> encrypted end to end with the server's host key
- tunnels die when the connection drops; `autossh` keeps them alive
- forwarding is disabled by default for locked-down accounts:
  `AllowTcpForwarding no` in sshd_config

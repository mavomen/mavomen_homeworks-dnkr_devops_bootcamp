# TCP vs UDP

## 1. Main Differences (5+)

1. **Connection-oriented vs connectionless**: TCP establishes a connection
   (3-way handshake) before sending data; UDP just sends packets with no setup.
2. **Reliability**: TCP guarantees delivery (acks + retransmission); UDP does
   not guarantee delivery at all.
3. **Ordering**: TCP reorders out-of-order segments; UDP has no ordering guarantee.
4. **Speed**: TCP is slower (headers, handshake, flow control); UDP is faster
   with minimal overhead.
5. **Flow/congestion control**: TCP manages window size and congestion; UDP has none.
6. **Header size**: TCP header 20-60 bytes; UDP header only 8 bytes.
7. **Use cases**: TCP for accuracy-critical transfers; UDP for real-time/loss-tolerant.

## 2. Best Protocol per Service

| Service              | Protocol | Reason                                                          |
|----------------------|----------|-----------------------------------------------------------------|
| Video Streaming      | UDP      | Real-time; a dropped frame is fine, low latency matters         |
| File Transfer (FTP)  | TCP      | Must be lossless and byte-exact                                  |
| DNS Query            | UDP      | Tiny request/response, one round-trip, fast; retry handles loss |
| Web Browsing (HTTP)  | TCP      | Pages must arrive complete and ordered                           |
| VoIP Call            | UDP      | Real-time voice; low latency, tolerate small packet loss        |
| Database Query       | TCP      | Queries/results must be reliable and ordered                     |

## 3. Protocols Currently in Use on This System

```
ss -tuln -> t = TCP, u = UDP
```

TCP and UDP sockets currently listening (from `ss -tuln`):

- TCP (LISTEN): 53 (systemd-resolved), 5432/5433 (postgres), 6379 (redis),
  5355 (LLMNR), 8086 (influxdb), 37933 (local app)
- UDP (UNCONN): 53 (systemd-resolved stub), 5353 (mDNS/avahi), 5355 (LLMNR),
  36755/36887 (ephemeral)

This shows the system uses BOTH: UDP for local name resolution/mDNS
(low-latency, loss-tolerant), TCP for database/cache services (must be reliable).

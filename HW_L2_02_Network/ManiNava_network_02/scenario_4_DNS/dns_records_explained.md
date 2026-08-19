# DNS Record Types

## 1. What each record does

| Type | Name | Purpose |
|------|------|---------|
| A | Address | maps a hostname to an **IPv4** address |
| AAAA | IPv6 Address | same but for **IPv6** (4x longer addresses) |
| CNAME | Canonical Name | alias pointing to another hostname (the other host's A/AAAA is then used) |
| MX | Mail Exchange | which mail server receives email for the domain (+ priority number) |
| TXT | Text | free-form text, mainly for verification: SPF, DKIM, domain ownership |
| NS | Name Server | which servers are authoritative for the zone |
| SOA | Start of Authority | zone metadata: primary NS, admin contact, serial + timing values |

SOA fields (from google.com below): serial `967711692` (bump on every zone
change - secondaries use it to detect updates), refresh 900s, retry 900s,
expire 1800s, negative-cache TTL 60s.

## 2. Real use cases

- **A**: `api.myapp.local -> 10.0.0.5` so apps reach the API by name.
- **AAAA**: same service reachable over IPv6 networks.
- **CNAME**: `www.example.com -> example.com` - one A record to maintain;
  also pointing `cdn.myapp.com` at a CloudFront distribution.
- **MX**: mail for `gmail.com` goes to `gmail-smtp-in.l.google.com`
  (priority 5), with alt servers 10-40 as fallback.
- **TXT**: SPF record says which servers may send mail as the domain
  (anti-spoofing); Google also uses TXT for docusign/onetrust ownership checks.
- **NS**: delegating `dev.myapp.local` to a separate team DNS server.
- **SOA**: serial-based replication between primary and secondary DNS.

## 3. Real dig examples

```bash
$ dig +noall +answer google.com A
google.com.     220  IN  A  192.178.192.113
google.com.     220  IN  A  192.178.192.102
...6 addresses total (round robin)

$ dig +noall +answer google.com AAAA
google.com.      31  IN  AAAA  2607:f8b0:4023:1804::8a
...

$ dig +noall +answer www.github.com CNAME
www.github.com. 3600 IN CNAME github.com.        # alias -> real A record

$ dig +noall +answer gmail.com MX
gmail.com.      2939 IN MX 5   gmail-smtp-in.l.google.com.
gmail.com.      2939 IN MX 10  alt1.gmail-smtp-in.l.google.com.
...priorities 5/10/20/30/40

$ dig +noall +answer google.com TXT
google.com.      99  IN TXT "onetrust-domain-verification=..."
google.com.      99  IN TXT "docusign=1b0a6754-..."
...

$ dig +noall +answer google.com NS
google.com.  341016 IN NS ns1.google.com.
...ns1-ns4

$ dig +noall +answer google.com SOA
google.com.      19  IN SOA ns1.google.com. dns-admin.google.com. 967711692 900 900 1800 60
```

note the TTL column (second value): google keeps A/AAAA TTLs very low
(31-220s) so it can reshuffle IPs fast; NS TTL is huge (~4 days).

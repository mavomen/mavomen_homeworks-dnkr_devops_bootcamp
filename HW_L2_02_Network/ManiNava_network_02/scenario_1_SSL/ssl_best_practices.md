# SSL/TLS Best Practices

## 1. SSL vs TLS

TLS is the newer, fixed version of SSL. SSL (last version 3.0) had known
weaknesses (POODLE, etc.) and is deprecated since 2015 - TLS 1.2 replaced it,
and TLS 1.3 is the current standard. The names are still used interchangeably
("SSL certificate", "SSL termination") but everything today actually runs TLS.

| | SSL (3.0) | TLS 1.2 / 1.3 |
|---|---|---|
| Status | deprecated, broken | current standard |
| Handshake | vulnerable to downgrade attacks | faster (1-RTT in 1.3), hardened |
| Ciphers | RC3/RC4, CBC issues | AEAD only (AES-GCM, ChaCha20) |

## 2. Self-signed vs CA-signed certificates

| | Self-signed | CA-signed |
|---|---|---|
| Trust | only trusted if you import it manually | trusted by every browser/OS out of the box |
| Cost | free | free (Let's Encrypt) or paid |
| Identity proof | none - anyone can write any CN | CA verifies you control the domain |
| Browser warning | yes, big red warning | no |
| Use case | internal/dev/test environments | anything public-facing |

## 3. Five best practices

1. **Use TLS 1.2 minimum, prefer TLS 1.3** - disable SSLv3/TLS 1.0/1.1 on the server.
2. **Strong cipher suites only** - AEAD ciphers (AES-GCM, ChaCha20-Poly1305),
   forward secrecy (ECDHE); disable RC4, 3DES, CBC-only suites.
3. **Automate certificate renewal** - e.g. certbot for Let's Encrypt (90-day certs);
   an expired cert takes the whole site down for users.
4. **Redirect all HTTP traffic to HTTPS** + enable HSTS so browsers refuse
   to downgrade.
5. **Keep private keys private** - correct permissions (600), never commit them
   to git, use separate keys per service.

## 4. Why HTTP is unsafe and how HTTPS fixes it

HTTP sends everything as plaintext. Anyone on the path (same wifi, ISP,
backbone) can read passwords/cookies/data and modify responses (inject ads,
malware) because there is no integrity check either.

HTTPS = HTTP inside a TLS tunnel:
- **Encryption**: traffic can't be read by middlemen (confidentiality)
- **Integrity**: tampering breaks the MAC/AEAD check and the connection fails
- **Authentication**: the certificate chain proves the server really is
  example.com, preventing man-in-the-middle impersonation

Verified live in `https_test_report.txt`: google.com negotiates TLSv1.3 with
an AES-256-GCM cipher, and `expired.badssl.com` is correctly rejected by curl
(error 60, "certificate has expired").

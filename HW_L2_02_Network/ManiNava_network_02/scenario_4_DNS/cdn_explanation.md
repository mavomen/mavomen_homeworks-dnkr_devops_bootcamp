# CDN and Caching

## 1. What a CDN is

CDN = Content Delivery Network. A geographically distributed set of proxy
servers that cache your static content (js, css, images, video) close to
users, so the content is served from a nearby edge instead of from your
origin server on another continent. Popular CDNs: Cloudflare, Akamai,
AWS CloudFront, Fastly (and jsDelivr for open source packages).

## 2. How it reduces latency

- **physical distance**: a request from Tehran to an origin in the US is
  ~150-250ms RTT; to a CDN edge in Frankfurt ~30-50ms.
- **caching**: the edge already has the file -> no trip to origin at all,
  response comes in one RTT.
- **connection reuse / TLS termination** at the edge, plus TCP optimizations
  (better peering between CDN and ISPs).
- **offloading the origin**: most requests never reach the origin server,
  so it stays fast and doesn't fall over under traffic spikes.

## 3. Origin server vs Edge server

| | Origin | Edge |
|---|---|---|
| role | the "real" server where content lives | cache/proxy close to the user |
| count | usually 1 (or a few per region) | hundreds of PoPs worldwide |
| has fresh data | yes, always | only what's cached (TTL-based) |
| cost per request | expensive (full app stack) | cheap (static file from RAM/disk) |

flow: user -> edge (cache HIT? serve) -> on MISS edge fetches from origin,
caches it, serves. TTL/expiry rules decide how long the copy stays valid.

## 4. Live proof - jsdelivr CDN headers

```bash
$ curl -I https://cdn.jsdelivr.net/npm/jquery@3.6.0/dist/jquery.min.js
HTTP/2 200
cache-control: public, max-age=31536000, s-maxage=31536000, immutable
age: 353361
x-served-by: cache-fra-etou8220040-FRA, cache-yul1970049-YUL
x-cache: HIT, HIT
```

reading these:
- `x-served-by: ...FRA...` -> my request was answered by the **Frankfurt**
  edge node (Fastly), not by jsdelivr's origin.
- `x-cache: HIT` -> the file was already cached at the edge, zero origin load.
- `age: 353361` -> this cached copy is ~4 days old and still valid.
- `cache-control: immutable, max-age=1y` -> versioned URL, browsers/edges can
  cache for a year without revalidating.

this is exactly why the file loads fast from anywhere: nearest edge + HIT.

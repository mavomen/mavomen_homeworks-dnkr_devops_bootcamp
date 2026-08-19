#!/usr/bin/env python3
# simple http server on port 8080 serving a small html page
import http.server
import socketserver
import os

SCEN_DIR = os.path.dirname(os.path.abspath(__file__))
os.chdir(SCEN_DIR)

PORT = 8080

# create the page we want to serve (only if missing)
if not os.path.exists("index.html"):
    with open("index.html", "w") as f:
        f.write("""<!DOCTYPE html>
<html>
<head><title>MyApp</title></head>
<body>
  <h1>Hello from MyApp</h1>
  <p>Simple HTTP server running on port 8080</p>
</body>
</html>
""")

Handler = http.server.SimpleHTTPRequestHandler

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Server at http://localhost:{PORT}", flush=True)
    httpd.serve_forever()

#!/usr/bin/env python3
# simple https server on port 8443 using the self-signed myapp.local cert
import http.server
import ssl
import os

SCEN_DIR = os.path.dirname(os.path.abspath(__file__))
os.chdir(SCEN_DIR)

server_address = ("localhost", 8443)
httpd = http.server.HTTPServer(server_address, http.server.SimpleHTTPRequestHandler)

# note: ssl.wrap_socket from the hint is removed in python 3.12+, use SSLContext instead
context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain(certfile="certs/myapp.crt", keyfile="certs/myapp.key")
httpd.socket = context.wrap_socket(httpd.socket, server_side=True)

print("Server running on https://localhost:8443", flush=True)
httpd.serve_forever()

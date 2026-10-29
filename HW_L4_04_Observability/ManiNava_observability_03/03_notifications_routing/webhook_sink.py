#!/usr/bin/env python3
"""Minimal local webhook sink used as an Alertmanager test receiver.

Listens on 0.0.0.0:<port> (default 5001). Every POST is printed to stdout and
appended to webhook_sink_log.txt next to this script. Alertmanager (in Docker)
reaches it via host.docker.internal (host-gateway mapping in docker-compose.yml).

Usage: webhook_sink.py [port]
"""
import datetime
import http.server
import json
import os
import sys

LOG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "webhook_sink_log.txt")


class Sink(http.server.BaseHTTPRequestHandler):
    # HTTP/1.1 + explicit Content-Length: without them the Alertmanager Go client
    # waits for connection close after the body, times out, and retries the POST
    # (notifications appeared duplicated in the sink log).
    protocol_version = "HTTP/1.1"

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        raw = self.rfile.read(length).decode("utf-8", "replace")
        try:
            pretty = json.dumps(json.loads(raw))
        except ValueError:
            pretty = raw
        stamp = datetime.datetime.now().isoformat(timespec="seconds")
        line = f"{stamp}  POST {self.path}  {pretty}"
        print(line, flush=True)
        with open(LOG, "a") as fh:
            fh.write(line + "\n")
        body = b"{}"
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass  # keep stdout to our own structured lines only


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 5001
    with http.server.ThreadingHTTPServer(("0.0.0.0", port), Sink) as httpd:
        print(f"webhook sink listening on 0.0.0.0:{port}", flush=True)
        httpd.serve_forever()

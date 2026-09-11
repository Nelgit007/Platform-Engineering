#!/usr/bin/env python3
"""
Minimal internal service used to demonstrate systemd service management.
Binds to 127.0.0.1 ONLY — it should never be directly internet-reachable,
which the firewall script enforces at the network level, not just here.
"""
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import datetime

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            body = {
                "status": "ok",
                "service": "app-service",
                "timestamp": datetime.datetime.utcnow().isoformat() + "Z"
            }
            self.wfile.write(json.dumps(body).encode())
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'{"error": "not found"}')

    def log_message(self, format, *args):
        pass  # keep journald output clean

if __name__ == "__main__":
    server = HTTPServer(("127.0.0.1", 5000), Handler)
    print("app-service listening on 127.0.0.1:5000")
    server.serve_forever()

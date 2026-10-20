#!/usr/bin/env python3
# Minimal internal service — just returns a health check response.
# Runs on localhost only; nginx is the only thing that talks to it.

from http.server import BaseHTTPRequestHandler, HTTPServer

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(b'{"status": "ok"}')

HTTPServer(("127.0.0.1", 5000), Handler).serve_forever()

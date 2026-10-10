#!/usr/bin/python3
"""Tiny HTTP bridge so UI tests (running inside the simulator) can change the
iPhone Duo fold state mid-test. The simulator shares the Mac's network, so the
test calls http://127.0.0.1:<port>/hinge?state=<closed|half|flat|0-180>&udid=<UDID>
and this server runs `duo-hinge` on the host.

Usage: tools/duo-hinge-server.py [--port 8765]
"""
import argparse
import os
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

DUO_HINGE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "duo-hinge")


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        url = urlparse(self.path)
        if url.path == "/ping":
            return self._reply(200, "ok")
        if url.path != "/hinge":
            return self._reply(404, "unknown path")

        query = parse_qs(url.query)
        state = query.get("state", [""])[0]
        udid = query.get("udid", ["booted"])[0]
        result = subprocess.run([DUO_HINGE, "-d", udid, state], capture_output=True, text=True)
        output = (result.stdout + result.stderr).strip()
        self._reply(200 if result.returncode == 0 else 500, output)

    def _reply(self, code, body):
        data = (body + "\n").encode()
        self.send_response(code)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt, *args):
        print("[duo-hinge-server] " + fmt % args, flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8765)
    args = parser.parse_args()
    if not os.access(DUO_HINGE, os.X_OK):
        raise SystemExit(f"{DUO_HINGE} not found; build it first (see README)")
    print(f"[duo-hinge-server] listening on 127.0.0.1:{args.port}", flush=True)
    ThreadingHTTPServer(("127.0.0.1", args.port), Handler).serve_forever()

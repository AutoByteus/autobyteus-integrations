"""A local stand-in for the AutoByteus proxy in front of GitHub, for the
deterministic tests of the GitHub integration's scripts.

It listens on 127.0.0.1 (an ephemeral port), serves the proxy-style address
/r/rp_test/github/api/<path>, records every request and answers from a routes
file the tests rewrite between cases. Python 3 standard library only; run it
with `python3 -I`.

Routes file: a JSON array of entries, the first match wins:
  {"method": "GET", "path": "/user", "match": "optional substring of the body",
   "status": 200, "body": <JSON value>}
or, for a non-JSON answer, "text": "<raw body>" instead of "body".
"path" includes the query string exactly as the script sends it.
An unmatched request gets HTTP 418 with {"message": "fake-api: no route ..."}.

Log file: one JSON object per request: method, path, headers, body.
"""

import argparse
import json
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

PREFIX = "/r/rp_test/github/api"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--routes", required=True)
    parser.add_argument("--log", required=True)
    parser.add_argument("--port-file", required=True)
    args = parser.parse_args()

    class Handler(BaseHTTPRequestHandler):
        def handle_any(self):
            length = int(self.headers.get("Content-Length") or 0)
            body = self.rfile.read(length).decode("utf-8") if length else ""
            path = self.path[len(PREFIX):] if self.path.startswith(PREFIX) else self.path
            with open(args.log, "a", encoding="utf-8") as log:
                log.write(json.dumps({
                    "method": self.command,
                    "path": path,
                    "prefixed": self.path.startswith(PREFIX),
                    "headers": {k.lower(): v for k, v in self.headers.items()},
                    "body": body,
                }) + "\n")

            with open(args.routes, encoding="utf-8") as f:
                routes = json.load(f)
            for route in routes:
                if route.get("method", "GET") != self.command or route["path"] != path:
                    continue
                if "match" in route and route["match"] not in body:
                    continue
                if "text" in route:
                    self.answer(route.get("status", 200), route["text"].encode("utf-8"), "text/html")
                else:
                    payload = json.dumps(route.get("body", {})).encode("utf-8")
                    self.answer(route.get("status", 200), payload, "application/json")
                return
            payload = json.dumps({"message": "fake-api: no route for %s %s" % (self.command, path)})
            self.answer(418, payload.encode("utf-8"), "application/json")

        def answer(self, status, payload, content_type):
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)

        do_GET = do_POST = do_PATCH = do_PUT = do_DELETE = handle_any

        def log_message(self, *_):
            pass

    server = HTTPServer(("127.0.0.1", 0), Handler)
    with open(args.port_file, "w", encoding="utf-8") as f:
        f.write(str(server.server_address[1]))
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())

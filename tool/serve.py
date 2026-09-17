# Serves build/web with caching disabled, so a rebuild is what the browser
# gets on the next reload. Plain `python -m http.server` sends no cache
# headers, and Chrome will happily keep an old main.dart.js for a while.
#
#   python3 tool/serve.py build/web [port]
import http.server, functools, sys
class H(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, must-revalidate')
        self.send_header('Expires', '0')
        super().end_headers()
    def log_message(self, *a): pass
port = int(sys.argv[2]) if len(sys.argv) > 2 else 8731
print(f'serving {sys.argv[1]} on http://localhost:{port} (no-cache)')
http.server.ThreadingHTTPServer(('127.0.0.1', port), functools.partial(H, directory=sys.argv[1])).serve_forever()

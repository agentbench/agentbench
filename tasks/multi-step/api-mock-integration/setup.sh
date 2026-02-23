#!/usr/bin/env bash
set -euo pipefail
WS="$1"

# Create the mock API server
cat > "$WS/mock_server.py" << 'PYEOF'
import http.server
import json
import sys

DATA = {
    "/api/users": [
        {"id": 1, "name": "Alice", "department": "Engineering", "active": True},
        {"id": 2, "name": "Bob", "department": "Sales", "active": True},
        {"id": 3, "name": "Carol", "department": "Engineering", "active": False},
        {"id": 4, "name": "David", "department": "Marketing", "active": True},
        {"id": 5, "name": "Eve", "department": "Sales", "active": True}
    ],
    "/api/projects": [
        {"id": 101, "name": "Project Alpha", "owner_id": 1, "status": "active", "budget": 50000},
        {"id": 102, "name": "Project Beta", "owner_id": 2, "status": "completed", "budget": 30000},
        {"id": 103, "name": "Project Gamma", "owner_id": 1, "status": "active", "budget": 75000},
        {"id": 104, "name": "Project Delta", "owner_id": 4, "status": "on-hold", "budget": 20000}
    ],
    "/api/metrics": {
        "total_revenue": 847500,
        "active_projects": 2,
        "team_size": 4,
        "avg_project_budget": 43750
    }
}

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path in DATA:
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(DATA[self.path]).encode())
        elif self.path == "/api/endpoints":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(list(DATA.keys())).encode())
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass  # Suppress logs

if __name__ == "__main__":
    server = http.server.HTTPServer(("localhost", 9876), Handler)
    with open(sys.argv[1] + "/mock_server.pid", "w") as f:
        import os
        f.write(str(os.getpid()))
    server.serve_forever()
PYEOF

# Start the server in background
python3 "$WS/mock_server.py" "$WS" &
# Wait for server to be ready
for i in $(seq 1 10); do
    if curl -s http://localhost:9876/api/endpoints > /dev/null 2>&1; then
        break
    fi
    sleep 0.5
done

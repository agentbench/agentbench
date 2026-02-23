#!/usr/bin/env bash
set -euo pipefail
WS="$1"

cat > "$WS/nginx.log" << 'EOF'
192.168.1.100 - - [15/Jan/2024:10:23:45 +0000] "GET /api/users HTTP/1.1" 200 1234
10.0.0.55 - - [15/Jan/2024:10:24:12 +0000] "POST /api/login HTTP/1.1" 401 89
192.168.1.100 - - [15/Jan/2024:10:25:00 +0000] "GET /api/dashboard HTTP/1.1" 200 5678
172.16.0.22 - - [15/Jan/2024:10:26:33 +0000] "GET /api/reports HTTP/1.1" 500 0
10.0.0.55 - - [15/Jan/2024:10:27:01 +0000] "POST /api/login HTTP/1.1" 200 445
192.168.1.200 - - [15/Jan/2024:10:28:15 +0000] "GET /static/logo.png HTTP/1.1" 304 0
10.0.0.88 - - [15/Jan/2024:10:29:45 +0000] "DELETE /api/users/5 HTTP/1.1" 403 120
172.16.0.22 - - [15/Jan/2024:10:30:00 +0000] "GET /api/reports HTTP/1.1" 500 0
192.168.1.100 - - [15/Jan/2024:10:31:22 +0000] "PUT /api/users/1 HTTP/1.1" 200 890
10.0.0.55 - - [15/Jan/2024:10:32:10 +0000] "GET /api/profile HTTP/1.1" 200 2345
EOF

cat > "$WS/syslog.log" << 'EOF'
Jan 15 10:20:01 webserver01 sshd[1234]: Accepted publickey for admin from 203.0.113.50 port 52341
Jan 15 10:21:15 webserver01 kernel: [ERROR] Out of memory: Kill process 5678 (java) score 900
Jan 15 10:22:30 webserver01 cron[2345]: (root) CMD (/usr/local/bin/backup.sh)
Jan 15 10:23:45 webserver01 sshd[1235]: Failed password for invalid user test from 198.51.100.23 port 44521
Jan 15 10:25:00 webserver01 systemd[1]: Started Apache HTTP Server.
Jan 15 10:26:12 webserver01 kernel: [ERROR] disk I/O error on sda1, sector 4096
Jan 15 10:27:30 webserver01 sshd[1236]: Accepted publickey for deploy from 203.0.113.51 port 52890
Jan 15 10:28:45 webserver01 kernel: [WARNING] CPU temperature above threshold, cpu clock throttled
Jan 15 10:30:01 webserver01 sshd[1237]: Failed password for root from 198.51.100.23 port 44600
Jan 15 10:31:15 webserver01 kernel: [ERROR] segfault at 0000000000000000 rip 00007f3b2c001234
EOF

cat > "$WS/app.log" << 'EOF'
2024-01-15 10:20:00 [INFO] Application started on port 8080
2024-01-15 10:21:30 [ERROR] ERR_DB_CONNECTION: Failed to connect to database at 10.0.1.50:5432
2024-01-15 10:22:00 [INFO] Retry connection to 10.0.1.50:5432 - attempt 2
2024-01-15 10:22:30 [INFO] Database connection established
2024-01-15 10:23:15 [WARN] Slow query detected: 2345ms for user lookup
2024-01-15 10:24:00 [ERROR] ERR_AUTH_FAILED: Invalid token from client 192.168.1.150
2024-01-15 10:25:30 [INFO] User session created for user_id=42
2024-01-15 10:26:45 [ERROR] ERR_RATE_LIMIT: Rate limit exceeded for IP 10.0.0.99 - 150 requests/min
2024-01-15 10:28:00 [WARN] Memory usage at 85% - consider scaling
2024-01-15 10:29:15 [ERROR] ERR_TIMEOUT: Request to /api/external timed out after 30s from 172.16.0.33
2024-01-15 10:30:30 [INFO] Health check passed
2024-01-15 10:31:00 [ERROR] ERR_FILE_NOT_FOUND: Template missing: invoice_template.html
EOF

cat > "$WS/auth.log" << 'EOF'
2024-01-15T10:20:15Z AUTH login_success user=admin ip=203.0.113.50 method=publickey
2024-01-15T10:21:00Z AUTH login_failed user=test ip=198.51.100.23 method=password reason=invalid_user
2024-01-15T10:22:45Z AUTH login_success user=deploy ip=203.0.113.51 method=publickey
2024-01-15T10:23:30Z AUTH token_refresh user=alice ip=192.168.1.100 status=success
2024-01-15T10:24:15Z AUTH login_failed user=root ip=198.51.100.23 method=password reason=wrong_password
2024-01-15T10:25:00Z AUTH login_success user=bob ip=10.0.0.55 method=password
2024-01-15T10:26:30Z AUTH permission_denied user=bob ip=10.0.0.55 resource=/admin reason=insufficient_role
2024-01-15T10:27:45Z AUTH login_failed user=admin ip=45.33.32.156 method=password reason=wrong_password
2024-01-15T10:29:00Z AUTH token_expired user=carol ip=192.168.1.200 action=forced_logout
2024-01-15T10:30:15Z AUTH login_success user=admin ip=203.0.113.50 method=publickey
EOF

cat > "$WS/access.log" << 'EOF'
[2024-01-15 10:20:30] 192.168.1.100 GET /dashboard 200 45ms
[2024-01-15 10:21:45] 10.0.0.55 POST /api/data 201 120ms
[2024-01-15 10:22:15] 192.168.1.100 GET /reports/q4 200 890ms
[2024-01-15 10:23:00] 172.16.0.22 GET /api/health 200 5ms
[2024-01-15 10:24:30] 10.0.0.88 DELETE /api/records/15 403 12ms
[2024-01-15 10:25:45] 192.168.1.200 GET /static/app.js 200 3ms
[2024-01-15 10:26:00] 45.33.32.156 POST /api/login 401 234ms
[2024-01-15 10:27:15] 10.0.0.99 GET /api/search?q=test 200 567ms
[2024-01-15 10:28:30] 192.168.1.100 PUT /api/settings 200 78ms
[2024-01-15 10:29:45] 172.16.0.33 GET /api/external/proxy 504 30001ms
EOF

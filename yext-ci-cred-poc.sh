#!/usr/bin/env bash
# Harvest REAL internal service names from the Go binaries in /scripts/bin,
# instead of guessing DNS names. Read-only: strings over files we can already read.
set +e
B="YEXTPOC7731"; echo "$B-BEGIN"
BINS="/scripts/bin/cbdservice /scripts/bin/artifactbundler"
ls -la $BINS 2>&1

ext(){ # $1=label $2=regex
  echo "--- $1 ---"
  for F in $BINS; do
    strings -n 6 "$F" 2>/dev/null | grep -aoE "$2" | sort -u | head -40 | sed "s|^|  [$(basename $F)] |"
  done
}

echo "$B === 1. CLUSTER DNS NAMES ==="
ext "svc.cluster.local" '[a-z0-9][a-z0-9.-]{2,60}\.svc\.cluster\.local'
echo "$B === 2. YEXT INTERNAL HOSTNAMES ==="
ext "yext hosts" '[a-z0-9][a-z0-9.-]{2,50}\.(yext|yextapis|yextenv)\.(com|net|internal|io)'
echo "$B === 3. GRPC TARGETS / HOST:PORT ==="
ext "host:port" '[a-z0-9][a-z0-9.-]{3,50}:(50051|8080|8443|9090|443|6379|3306|5432|9200)'
echo "$B === 4. SERVICE-DISCOVERY ENV VARS ==="
ext "env names" '[A-Z][A-Z0-9_]{4,40}_(HOST|ADDR|ADDRESS|URL|ENDPOINT|PORT|SERVICE|TARGET)'
echo "$B === 5. INTERNAL HTTP(S) URLS ==="
ext "urls" 'https?://[a-z0-9][a-zA-Z0-9._/-]{4,70}'
echo "$B === 6. GRPC SERVICE/METHOD NAMES ==="
ext "grpc paths" '/[a-z][a-zA-Z0-9_.]{4,50}\.[A-Z][a-zA-Z0-9]{2,40}/[A-Z][a-zA-Z0-9]{2,40}'

echo "$B-END"; exit 0

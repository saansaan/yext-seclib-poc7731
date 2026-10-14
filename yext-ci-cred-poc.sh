#!/usr/bin/env bash
# Extract the FULL internal gRPC method catalog from the Go binaries.
# Go gRPC clients embed every "/pkg.Service/Method" they invoke.
set +e
B="YEXTPOC7731"; echo "$B-BEGIN"
strings -n 8 /scripts/bin/cbdservice /scripts/bin/artifactbundler 2>/dev/null \
 | grep -aoE '/[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*\.[A-Z][A-Za-z0-9]+/[A-Z][A-Za-z0-9]+' \
 | sort -u > /tmp/m.txt
echo "$B total_method_paths=$(wc -l < /tmp/m.txt)"
echo "$B distinct_services=$(sed -E 's#^/(.*)/[^/]+$#\1#' /tmp/m.txt | sort -u | wc -l)"
echo "$B-SERVICES-START"
sed -E 's#^/(.*)/[^/]+$#\1#' /tmp/m.txt | sort | uniq -c | sort -rn
echo "$B-SERVICES-END"
echo "$B-METHODS-START"
cat /tmp/m.txt
echo "$B-METHODS-END"
echo "$B-END"; exit 0

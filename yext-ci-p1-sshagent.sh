#!/usr/bin/env bash
# Broad SECRET sweep of the shipped Go binaries - the prior pass only grepped host/user/password.
# Hunting signing keys, cloud creds and API tokens. Output is bounded + de-duplicated.
set +e
B="YEXTP8"; echo "$B-BEGIN"
BINS="/scripts/bin/cbdservice /scripts/bin/artifactbundler"
echo "$B-HIGHSIG-START"
# high-confidence vendor token formats
strings -n 12 $BINS 2>/dev/null \
 | grep -aoE 'AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36,}|ghs_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{40,}|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35}|sk_live_[0-9a-zA-Z]{20,}|SG\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}|glpat-[A-Za-z0-9_-]{20}|dop_v1_[a-f0-9]{64}|eyJ[A-Za-z0-9_-]{20,}\.eyJ[A-Za-z0-9_-]{20,}' \
 | sort -u | head -60
echo "$B-HIGHSIG-END"
echo "$B-PRIVKEY-START"
strings -n 20 $BINS 2>/dev/null | grep -aoE -- '-----BEGIN [A-Z ]*PRIVATE KEY-----' | sort | uniq -c
echo "$B-PRIVKEY-END"
echo "$B-SIGNING-START"
# config-style keys whose NAME implies signing/crypto, with their value
strings -n 6 $BINS 2>/dev/null \
 | grep -aoiE '^ *(signing[_a-z]*|hmac[_a-z]*|[a-z_]*secret[_a-z]*|[a-z_]*salt|[a-z_]*pepper|jwt[_a-z]*|[a-z_]*private_key|[a-z_]*api_key|[a-z_]*apikey|[a-z_]*access_key|[a-z_]*token)\s*:\s*[^ ].{6,90}$' \
 | sed 's/[[:space:]]\+/ /g' | sort -u | head -80
echo "$B-SIGNING-END"
echo "$B-COUNTS-START"
for f in $BINS; do
  echo "--- $f size=$(stat -c %s "$f" 2>/dev/null)"
  echo "    colon-config lines: $(strings -n 6 "$f" 2>/dev/null | grep -acE '^ *[a-z0-9_.-]+: ')"
done
echo "$B-COUNTS-END"
echo "$B-VALIDATOR-START"
# the validator image layer is a separate npm tree - check it for creds too
ls -la /opt/yextci-validator 2>&1 | head -10
for f in /opt/yextci-validator/.npmrc /opt/yextci-validator/node_modules/.package-lock.json; do
  echo "--- $f"; [ -f "$f" ] && head -c 300 "$f"
done
echo "$B-VALIDATOR-END"
echo "$B-END"; exit 0

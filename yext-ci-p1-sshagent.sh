#!/usr/bin/env bash
# Fingerprint whatever answers on the link-local metadata address from inside the build container.
# READ ONLY. If credentials appear, they are NOT used.
set +e
B="YEXTP3"; echo "$B-BEGIN"
M=169.254.169.254
hdr(){ echo "--- $1"; curl -s -m 5 -D - -o /tmp/body.txt ${3:+-H "$3"} "$2" 2>&1 | head -12; echo "[body first 400]"; head -c 400 /tmp/body.txt 2>/dev/null; echo; }
echo "$B-ROOT-START"
hdr "root /"                 "http://$M/"
hdr "latest/"                "http://$M/latest/"
hdr "latest/meta-data/"      "http://$M/latest/meta-data/"
echo "$B-ROOT-END"
echo "$B-AWS-START"
echo "--- IMDSv2 token PUT"
curl -s -m 5 -X PUT -D - -o /tmp/tok.txt -H 'X-aws-ec2-metadata-token-ttl-seconds: 60' "http://$M/latest/api/token" 2>&1 | head -8
echo "[token first 60]"; head -c 60 /tmp/tok.txt 2>/dev/null; echo
TOK=$(cat /tmp/tok.txt 2>/dev/null)
if [ -n "$TOK" ]; then
  echo "--- IMDSv2 meta-data listing"
  curl -s -m 5 -H "X-aws-ec2-metadata-token: $TOK" "http://$M/latest/meta-data/" 2>&1 | head -30
  echo; echo "--- IMDSv2 iam role listing"
  curl -s -m 5 -H "X-aws-ec2-metadata-token: $TOK" "http://$M/latest/meta-data/iam/security-credentials/" 2>&1 | head -5
fi
echo "$B-AWS-END"
echo "$B-GCP-START"
hdr "gcp v1"      "http://$M/computeMetadata/v1/?recursive=false"  "Metadata-Flavor: Google"
hdr "gcp name"    "http://metadata.google.internal/computeMetadata/v1/instance/hostname" "Metadata-Flavor: Google"
echo "$B-GCP-END"
echo "$B-AZURE-START"
hdr "azure"       "http://$M/metadata/instance?api-version=2021-02-01" "Metadata: true"
echo "$B-AZURE-END"
echo "$B-MISC-START"
for p in /openstack /latest/dynamic/instance-identity/document /metrics /healthz /debug/pprof/ /v1/ /api/v1/; do
  echo "--- $p : $(curl -s -m 4 -o /dev/null -w 'http=%{http_code} len=%{size_download}' "http://$M$p" 2>&1)"
done
echo "$B-MISC-END"
echo "$B-END"; exit 0

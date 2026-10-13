#!/usr/bin/env bash
# Can the build sandbox ROUTE to Yext's internal 10.204.0.0/16?
# TCP reachability ONLY. No authentication attempted against any service.
set +e
B="YEXTPOC7731"; echo "$B-BEGIN"

echo "$B === 1. DNS from inside: do the internal names resolve to 10.204.x here? ==="
for H in review-topics-us2-dev.cluster-crbwrdn1iqrw.us-east-1.rds.amazonaws.com \
         app-sql01.dev.us3.yext.com whs-sql01.dev.us3.yext.com; do
  printf '  %-72s ' "${H:0:70}"
  getent hosts "$H" 2>&1 | head -1 | awk '{print $1}' || echo "NO RESOLVE"
done

echo "$B === 2. TCP REACHABILITY to 10.204.0.0/16 (by IP - DNS bypassed) ==="
python3 - <<'PY'
import socket
tgts=[("10.204.98.43",[3306,5432,1433]),   # the RDS instance we hold a credential for
      ("10.204.0.91",[3306,443,8080]),
      ("10.204.32.187",[3306,443]),
      ("10.204.64.102",[3306,443]),
      ("10.204.97.179",[3306,443])]
for ip,ports in tgts:
    for p in ports:
        s=socket.socket(); s.settimeout(5)
        try:
            s.connect((ip,p)); print(f"  {ip}:{p}  *** OPEN - ROUTABLE ***")
        except Exception as e:
            print(f"  {ip}:{p}  {type(e).__name__}")
        finally: s.close()
PY

echo "$B === 3. CONTROLS (prove the test harness works) ==="
python3 - <<'PY'
import socket
for ip,p,label in [("10.192.32.1",443,"GKE apiserver (known OPEN)"),
                   ("10.255.255.254",3306,"unrouted RFC1918 (known CLOSED)")]:
    s=socket.socket(); s.settimeout(5)
    try: s.connect((ip,p)); print(f"  {label:34s} {ip}:{p} OPEN")
    except Exception as e: print(f"  {label:34s} {ip}:{p} {type(e).__name__}")
    finally: s.close()
PY
echo "$B === 4. route table ==="
cat /proc/net/route 2>&1 | head -6
echo "$B-END"; exit 0

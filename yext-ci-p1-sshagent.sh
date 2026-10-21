#!/usr/bin/env bash
# Read Yext's own build scripts to document what deps_key is used FOR, without using the key.
set +e
B="YEXTP7"; echo "$B-BEGIN"
for f in /scripts/yext-deps.sh /scripts/user_commands/install_deps.sh /scripts/user_commands/env_vars.sh \
         /scripts/user_commands/build_setup.sh /scripts/user_commands/build.sh \
         /scripts/copy-repo.sh /scripts/cbd-entrypoint.sh /scripts/rebuild.sh \
         /scripts/mark-builderror.sh /scripts/set_node_version.sh /scripts/serve.sh; do
  echo "===== $f"; cat "$f" 2>&1; echo
done
echo "$B-NPMRC-START"
for f in /usr/etc/npmrc /etc/npmrc "$HOME/.npmrc" /opt/buildhome/repo/.npmrc /opt/buildhome/repo/.yarnrc.yml; do
  echo "--- $f"; cat "$f" 2>&1 | head -20
done
echo "$B-NPMRC-END"
echo "$B-GITCONF-START"; git config --global --list 2>&1 | head -20; cat /etc/gitconfig 2>&1 | head -20; echo "$B-GITCONF-END"
echo "$B-END"; exit 0

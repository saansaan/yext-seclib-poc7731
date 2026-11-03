#!/usr/bin/env bash
# IDENTITY ONLY. Resolves WHICH GitHub principal deps_key is, to replace a
# provenance inference with evidence. Reads NO repository content:
#   ssh -T git@github.com  returns a greeting and exits; it cannot transfer a repo.
# Explicitly NOT done: clone/fetch/ls-remote of any repo, and no push.
set +e
B="YEXTID"; echo "$B-BEGIN"
echo "$B agent=$(ssh-add -l 2>&1)"
echo "$B-WHOAMI-START"
# -o BatchMode: never prompt. StrictHostKeyChecking=yes uses the image's own known_hosts.
ssh -T -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=15 git@github.com 2>&1 | head -5
echo "$B whoami_exit=$?"
echo "$B-WHOAMI-END"
echo "$B-END"; exit 0

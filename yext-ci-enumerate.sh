#!/usr/bin/env bash
# ENUMERATE what the deps_key credential relates to, WITHOUT using it.
# Local filesystem reads only. No ssh, no git fetch, no network, no auth.
set +e
B="YEXTENUM"; echo "$B-BEGIN"

echo "$B-SCRIPTS-START"
find /scripts -maxdepth 3 \( -type f -o -type l \) -printf '%M %6s %p\n' 2>/dev/null | sort -k3 | head -60
echo "$B-SCRIPTS-END"

echo "$B-YEXTDEPS-START"
for f in /scripts/yext-deps.sh /scripts/user_commands/install_deps.sh /scripts/user_commands/build_setup.sh; do
  echo "--- $f ---"; cat "$f" 2>&1 | head -40
done
echo "$B-YEXTDEPS-END"

# where are Yext's own pre-staged JS deps? yext-deps.sh takes a dir as $1
echo "$B-DEPDIRS-START"
for d in /opt/yext-deps /opt/deps /opt/js_deps /opt/buildhome/deps /yext-deps /deps /opt/yextci-validator; do
  echo "--- $d ($([ -d "$d" ] && echo DIR || echo absent))"
  [ -d "$d" ] && ls -la "$d" 2>&1 | head -25
done
echo "-- any dir named *dep* under /opt /usr/local /srv --"
find /opt /usr/local /srv -maxdepth 4 -type d -iname '*dep*' 2>/dev/null | head -20
echo "$B-DEPDIRS-END"

# .git/config inside ANY pre-staged dep names the private repo with zero auth
echo "$B-DEPGIT-START"
find / -maxdepth 7 -path /proc -prune -o -name config -path '*/.git/*' -print 2>/dev/null | head -30 | while read -r c; do
  u=$(grep -aoE 'url *=.*' "$c" 2>/dev/null | head -2)
  [ -n "$u" ] && echo "$c :: $u"
done
echo "$B-DEPGIT-END"

# installed @yext packages: declared repo + where npm actually got them
echo "$B-INSTALLED-START"
for p in /opt/buildhome/repo/node_modules/@yext/*; do
  [ -d "$p" ] || continue
  n=$(basename "$p")
  v=$(python3 -c "import json;print(json.load(open('$p/package.json')).get('version',''))" 2>/dev/null)
  r=$(python3 -c "import json;d=json.load(open('$p/package.json'));r=d.get('repository');print(r if isinstance(r,str) else (r or {}).get('url',''))" 2>/dev/null)
  rs=$(python3 -c "import json;print(json.load(open('$p/package.json')).get('_resolved',''))" 2>/dev/null)
  echo "$n v=$v repo=$r resolved=$rs"
done
echo "$B-INSTALLED-END"

echo "$B-PRIVATE-MARKERS-START"
echo "-- any node_modules pkg resolved over git/ssh --"
grep -rlsE '"_resolved": *"(git|ssh)' /opt/buildhome/repo/node_modules 2>/dev/null | head -20
echo "-- any package.json marked private:true --"
grep -rlsE '"private": *true' /opt/buildhome/repo/node_modules/@yext 2>/dev/null | head -20
echo "-- npmrc/registry overrides anywhere --"
find / -maxdepth 6 -name '.npmrc' -o -maxdepth 6 -name 'npmrc' 2>/dev/null | head -10
echo "$B-PRIVATE-MARKERS-END"

echo "$B-END"; exit 0

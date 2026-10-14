#!/usr/bin/env bash
# Find the consumer of PlatformRedirects file_name: is it written to disk by path?
# READ-ONLY string analysis of binaries already readable in this container.
set +e
B="YEXTPOC7731"; echo "$B-BEGIN"
BINS="/scripts/bin/cbdservice /scripts/bin/artifactbundler"

echo "$B === 1. redirects-related symbols / strings ==="
strings -n 5 $BINS 2>/dev/null | grep -aiE 'redirect' | sort -u | head -45

echo "$B === 2. Go symbols touching redirects (function names) ==="
strings -n 8 $BINS 2>/dev/null \
 | grep -aoE '[a-zA-Z0-9_/.()*]+[Rr]edirect[A-Za-z0-9_]*' | sort -u | head -40

echo "$B === 3. does anything join a filename into an output dir? ==="
strings -n 6 $BINS 2>/dev/null \
 | grep -aiE 'filepath\.(Join|Clean|Abs)|outputprefix|artifacts/|/redirects' | sort -u | head -25

echo "$B === 4. artifactbundler usage/flags (how file_name is consumed) ==="
/scripts/bin/artifactbundler --help 2>&1 | head -40

echo "$B-END"; exit 0

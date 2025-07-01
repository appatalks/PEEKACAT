#!/usr/bin/env bash
# wipe-year.sh – drop all commits authored in YEAR, keep the rest
# USAGE: ./wipe-year.sh <repo-url> [year]
# USE WITH CAUTION
set -euo pipefail

REPO="${1:?need repo URL}"
YEAR="${2:-2009}"

TMP=$(mktemp -d)
git clone --bare "$REPO" "$TMP"
cd "$TMP"

git filter-repo --force --commit-callback '
import datetime, re, sys
raw = commit.author_date
if isinstance(raw, (bytes, bytearray)):
    raw = raw.decode()
unix = int(re.split(r"\s+", raw)[0])
if datetime.datetime.utcfromtimestamp(unix).year == int("'"$YEAR"'"):
    commit.skip()
'

# prune refs GitHub won’t accept
git for-each-ref --format="%(refname)" refs/pull/* refs/replace/* | \
  xargs -r -n1 git update-ref -d

# push new history
git push --force --all
git push --force --tags
echo "✅ Finished: all $YEAR commits removed and repo pushed."

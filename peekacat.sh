#!/usr/bin/env bash
set -euo pipefail

# Add PEEKACAT to 2008 GitHub Contribution graph
# For Git SSH
# Replace <OWNER>/<REPO>
REPO="git@github.com:<OWNER>/<REPO>.git"

# Add if not set:
# git config user.name  ""
# git config user.email ""

###############################################################################
# Do not edit below this line
# --- discover the repo’s default branch (main / master / custom) -------------
DEFAULT=$(git ls-remote --symref "$REPO" HEAD \
          | awk '/^ref:/ {sub("refs/heads/","",$2); print $2}')

WORK=$(mktemp -d)
git clone --quiet "$REPO" "$WORK"
cd "$WORK"
git checkout "$DEFAULT"

# ----------------------------------------------------------------------------- 
python3 <<'PY'
import datetime, subprocess, os

# ─── 1. 5×5 pixel font for the needed letters ────────────────────────────────
FONT = {
 'A':["01110","10001","11111","10001","10001"],
 'C':["01111","10000","10000","10000","01111"],
 'E':["11111","10000","11110","10000","11111"],
 'K':["10001","10010","11100","10010","10001"],
 'P':["11110","10001","11110","10000","10000"],
 'T':["11111","00100","00100","00100","00100"],
}

MESSAGE = "PEEKACAT"
ROWS, COLS = 7, 53           # GitHub year grid
GRID = [[0]*COLS for _ in range(ROWS)]

# ─── 2. horizontal & vertical centering ──────────────────────────────────────
total_width = len(MESSAGE)*5 + (len(MESSAGE)-1)  # 5-px chars + 1-px gaps
left_pad = (COLS - total_width)//2               # =3 for this case
top_pad  = (ROWS - 5)//2                         # =1  so rows 1-5 are used

col = left_pad
for ch in MESSAGE:
    glyph = FONT[ch]
    for r_local, row_bits in enumerate(glyph):
        for c_local, bit in enumerate(row_bits):
            if bit == '1':
                GRID[top_pad + r_local][col + c_local] = 1
    col += 6   # 5 columns of glyph + 1 column gap

# ─── 3. commit once for every “on” pixel ─────────────────────────────────────
BASE_SUNDAY = datetime.date(2007, 12, 30)   # Sunday before 2008

def commit_at(day_iso):
    ts = f"{day_iso}T12:00:00"
    env = dict(os.environ, GIT_AUTHOR_DATE=ts, GIT_COMMITTER_DATE=ts)
    subprocess.run("git commit --allow-empty -m pixel", shell=True,
                   check=True, env=env)

for x in range(COLS):
    for y in range(ROWS):
        if GRID[y][x]:
            date = BASE_SUNDAY + datetime.timedelta(days=x*7 + y)
            commit_at(date)

PY
# ----------------------------------------------------------------------------- 

git push --quiet origin "$DEFAULT"
echo "Done!  View your 2008 contributions — and see “PEEKACAT” meowtooo."

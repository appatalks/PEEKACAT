#!/usr/bin/env bash
set -euo pipefail

# Add custom message to GitHub Contribution graph for specified year
# For Git SSH
# Replace <OWNER>/<REPO>
REPO="git@github.com:<OWNER>/<REPO>.git"

# Add if not set:
# git config user.name  ""
# git config user.email ""

# Default values
YEAR=2008
MESSAGE="PEEKACAT"
BAD_MODE=false
DRY_RUN=false
OWNER_REPO=""
SUPER_CLEAN=false  # Super clean option for complete history rewrite
MESSAGE_SET_BY_USER=false  # Track if user explicitly set a message

# Function to show help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Generate a custom GitHub contribution graph with a message for a specified year.

OPTIONS:
    -y, --year YEAR      Target year for the contribution graph (default: 2008)
    -m, --message MSG    Custom message to display (max 8 characters, default: PEEKACAT)
    -b, --bad            Enable bad mode - creates realistic heavy activity background
                         If used with -m, overlays message on background
                         If used alone, creates just the background without message
    -d, --dry-run        Generate PNG preview without making commits
    -o, --owner-repo     GitHub repository in format OWNER/REPO (overrides REPO variable)
    -s, --super-clean    Use super-aggressive history cleaning (removes ALL history)
    -h, --help           Show this help message

EXAMPLES:
    $0 -y 2020 -m "HELLO"                  # Display "HELLO" for 2020
    $0 --year 2023 --message "CODE" --bad  # Display "CODE" with heavy background
    $0 -b -y 2019                          # Just heavy background, no message
    $0 -d -m "TEST" -y 2024                # Preview "TEST" for 2024
    $0 -o "username/my-repo" -m "CODE" -y 2024  # Use different repo
    $0 -y 2022 -m "FIX" -s                 # Super clean - removes all history!

NOTE: Make sure to replace <OWNER>/<REPO> in the REPO variable with your actual repository.
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--year)
            YEAR="$2"
            shift 2
            ;;
        -m|--message)
            MESSAGE="$2"
            MESSAGE_SET_BY_USER=true
            if [[ ${#MESSAGE} -gt 8 ]]; then
                echo "Error: Message must be 8 characters or less" >&2
                exit 1
            fi
            shift 2
            ;;
        -b|--bad)
            BAD_MODE=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -o|--owner-repo)
            OWNER_REPO="$2"
            shift 2
            ;;
        -s|--super-clean)
            SUPER_CLEAN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Use -h or --help for usage information" >&2
            exit 1
            ;;
    esac
done

# Validate year
if ! [[ "$YEAR" =~ ^[0-9]{4}$ ]] || [ "$YEAR" -lt 2008 ]; then
    echo "Error: Year must be a 4-digit number and 2008 or later" >&2
    exit 1
fi

# Convert message to uppercase for consistency
MESSAGE=$(echo "$MESSAGE" | tr '[:lower:]' '[:upper:]')

# Override REPO if owner-repo is provided
if [ -n "$OWNER_REPO" ]; then
    # Validate format (should be OWNER/REPO)
    if [[ ! "$OWNER_REPO" =~ ^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$ ]]; then
        echo "Error: Owner/repo must be in format 'owner/repo' (e.g., 'username/my-repo')" >&2
        exit 1
    fi
    REPO="git@github.com:${OWNER_REPO}.git"
    echo "📁 Using repository: $OWNER_REPO"
fi

###############################################################################
# Do not edit below this line

if [ "$DRY_RUN" = true ]; then
    echo "🎨 Dry-run mode: Generating PNG preview..."
    
    # Pass variables to Python script
    export MESSAGE="$MESSAGE"
    export YEAR="$YEAR"
    export BAD_MODE="$BAD_MODE"
    export DRY_RUN="$DRY_RUN"
    export MESSAGE_SET_BY_USER="$MESSAGE_SET_BY_USER"
    
    echo "🐍 Starting Python script..."
    # Skip Git operations and go straight to visualization
else
    # --- discover the repo's default branch (main / master / custom) -------------
    DEFAULT=$(git ls-remote --symref "$REPO" HEAD \
              | awk '/^ref:/ {sub("refs/heads/","",$2); print $2}')

    WORK=$(mktemp -d)
    git clone --quiet "$REPO" "$WORK"
    cd "$WORK"
    git checkout "$DEFAULT"

    # Clean up any leftover temporary branches from previous runs
    git branch -D $(git branch --list "temp-clean-*") 2>/dev/null || true

    # Check if we need to clean existing commits for this year
    echo "🧹 Checking for existing commits from $YEAR..."
    ALL_EXISTING_COMMITS=$(git log --oneline --since="$YEAR-01-01" --until="$((YEAR+1))-01-01" | wc -l)
    PIXEL_COMMITS=$(git log --oneline --since="$YEAR-01-01" --until="$((YEAR+1))-01-01" --grep="pixel" | wc -l)
    
    echo "📊 Found $ALL_EXISTING_COMMITS total commits in $YEAR ($PIXEL_COMMITS with 'pixel' message)"
    
    # Create a backup of the current state regardless of cleaning mode
    BACKUP_TAG="backup-before-peekacat-$(date +%s)"
    git tag "$BACKUP_TAG" 2>/dev/null || true
    echo "💾 Created backup tag: $BACKUP_TAG"

    if [ "$SUPER_CLEAN" = true ]; then
        echo "🧨 SUPER CLEAN MODE: Will remove ALL history and start fresh!"
        echo "⚠️  This is a destructive operation that cannot be undone!"
        
        echo "🧨 Creating new orphan branch with no history..."
        
        # Use a consistent timestamp for the branch name
        CLEAN_TIMESTAMP=$(date +%s)
        CLEAN_BRANCH="clean-slate-$CLEAN_TIMESTAMP"
        
        # Create an orphan branch, then force the default branch to it
        # This creates a completely clean slate
        git checkout --orphan "$CLEAN_BRANCH"
        
        # Create an initial commit with just a README
        echo "# PEEKACAT Contribution Art Repository" > README.md
        echo "Created on $(date)" >> README.md
        git add README.md
        git commit -m "Initial commit - clean slate" --quiet
        
        # Force the default branch to this new state
        git checkout "$DEFAULT"
        git reset --hard "$CLEAN_BRANCH"
        
        # Clean up 
        git branch -D "$CLEAN_BRANCH" 2>/dev/null || true
        
        echo "✅ Complete history reset successful"
        EXISTING_COMMITS=0
        
        # Force push the clean slate immediately to sync with remote
        echo "🚀 Force-pushing clean slate to remote..."
        git push --force-with-lease origin "$DEFAULT" || {
            echo "⚠️  Force push failed, trying regular force push..."
            git push --force origin "$DEFAULT"
        }
        
        # Initialize billboard.txt 
        echo "PEEKACAT pixel art repository" > billboard.txt
        git add billboard.txt
        git commit -m "Initialize billboard.txt" --quiet || true
        
        # Push the billboard.txt commit
        git push --quiet origin "$DEFAULT" || true
    
    elif [ "$ALL_EXISTING_COMMITS" -gt 0 ]; then
        echo "⚠️  WARNING: Existing commits detected in $YEAR - will clean history"
        
        # Simple history cleaning approach
        TEMP_BRANCH="temp-clean-$(date +%s)"
        git checkout -b "$TEMP_BRANCH"
        
        # Filter out commits from target year
        git filter-branch -f --commit-filter '
            AUTHOR_YEAR=$(git show -s --format=%ad --date=format:%Y "$GIT_COMMIT")
            COMMITTER_YEAR=$(git show -s --format=%cd --date=format:%Y "$GIT_COMMIT")
            if [ "$AUTHOR_YEAR" = "'"$YEAR"'" ] || [ "$COMMITTER_YEAR" = "'"$YEAR"'" ]; then
                skip_commit "$@"
            else
                git commit-tree "$@"
            fi
        ' HEAD 2>/dev/null && {
            git checkout "$DEFAULT"
            git reset --hard "$TEMP_BRANCH"
            git branch -D "$TEMP_BRANCH"
            echo "✅ History cleaned successfully"
            EXISTING_COMMITS=0
        } || {
            echo "⚠️  History cleaning failed - proceeding additively"
            git checkout "$DEFAULT"
            git branch -D "$TEMP_BRANCH" 2>/dev/null || true
            EXISTING_COMMITS=$ALL_EXISTING_COMMITS
        }
    else
        echo "✅ No existing commits found in $YEAR - starting with clean slate"
        EXISTING_COMMITS=0
    fi

    # Ensure billboard.txt exists
    if [ ! -f "billboard.txt" ]; then
        echo "📝 Creating billboard.txt..."
        echo "PEEKACAT pixel art repository" > billboard.txt
        git add billboard.txt
        git commit -m "Initialize billboard.txt" --quiet || true
    fi

    # Pass variables to Python script
    export MESSAGE="$MESSAGE"
    export YEAR="$YEAR"
    export BAD_MODE="$BAD_MODE"
    export DRY_RUN="$DRY_RUN"
    export EXISTING_COMMITS="$EXISTING_COMMITS"
    export SUPER_CLEAN="$SUPER_CLEAN"
    export MESSAGE_SET_BY_USER="$MESSAGE_SET_BY_USER"
fi

# ----------------------------------------------------------------------------- 
python3 <<'PY'
import datetime, subprocess, os, sys, random

# ─── 1. 5×5 pixel font for letters ───────────────────────────────────────────
FONT = {
 'A':["01110","10001","11111","10001","10001"],
 'B':["11110","10001","11110","10001","11110"],
 'C':["01111","10000","10000","10000","01111"],
 'D':["11110","10001","10001","10001","11110"],
 'E':["11111","10000","11110","10000","11111"],
 'F':["11111","10000","11110","10000","10000"],
 'G':["01111","10000","10111","10001","01111"],
 'H':["10001","10001","11111","10001","10001"],
 'I':["11111","00100","00100","00100","11111"],
 'J':["11111","00010","00010","10010","01100"],
 'K':["10001","10010","11100","10010","10001"],
 'L':["10000","10000","10000","10000","11111"],
 'M':["10001","11011","10101","10001","10001"],
 'N':["10001","11001","10101","10011","10001"],
 'O':["01110","10001","10001","10001","01110"],
 'P':["11110","10001","11110","10000","10000"],
 'Q':["01110","10001","10101","10010","01101"],
 'R':["11110","10001","11110","10010","10001"],
 'S':["01111","10000","01110","00001","11110"],
 'T':["11111","00100","00100","00100","00100"],
 'U':["10001","10001","10001","10001","01110"],
 'V':["10001","10001","10001","01010","00100"],
 'W':["10001","10001","10101","11011","10001"],
 'X':["10001","01010","00100","01010","10001"],
 'Y':["10001","01010","00100","00100","00100"],
 'Z':["11111","00010","00100","01000","11111"],
 '0':["01110","10001","10001","10001","01110"],
 '1':["00100","01100","00100","00100","01110"],
 '2':["01110","10001","00110","01000","11111"],
 '3':["01110","10001","00110","10001","01110"],
 '4':["10001","10001","11111","00001","00001"],
 '5':["11111","10000","11110","00001","11110"],
 '6':["01110","10000","11110","10001","01110"],
 '7':["11111","00001","00010","00100","01000"],
 '8':["01110","10001","01110","10001","01110"],
 '9':["01110","10001","01111","00001","01110"],
}

# Get parameters from environment (passed from bash)
MESSAGE = os.environ.get('MESSAGE', 'PEEKACAT')
YEAR = int(os.environ.get('YEAR', '2008'))
BAD_MODE = os.environ.get('BAD_MODE', 'false').lower() == 'true'
DRY_RUN = os.environ.get('DRY_RUN', 'false').lower() == 'true'
MESSAGE_SET_BY_USER = os.environ.get('MESSAGE_SET_BY_USER', 'false').lower() == 'true'

# Validate message characters
for char in MESSAGE:
    if char not in FONT:
        print(f"Error: Character '{char}' not supported in font", file=sys.stderr)
        sys.exit(1)

ROWS, COLS = 7, 53           # GitHub year grid
GRID = [[0]*COLS for _ in range(ROWS)]

if BAD_MODE:
    # Simulate realistic but deceptively heavy activity with message emphasis
    import random
    random.seed(YEAR)  # Consistent results for same year
    
    # Calculate the base Sunday for the target year
    if YEAR == 2008:
        # Use original calculation for 2008
        BASE_SUNDAY = datetime.date(2007, 12, 30)
    else:
        # For other years, find the Sunday before January 1st
        base_date = datetime.date(YEAR, 1, 1)
        days_to_sunday = base_date.weekday()
        if days_to_sunday == 6:  # If Jan 1 is Sunday
            BASE_SUNDAY = base_date
        else:
            # Go back to the previous Sunday
            BASE_SUNDAY = base_date - datetime.timedelta(days=(days_to_sunday + 1) % 7)
    
    # Define some holidays (approximate dates)
    holidays = set()
    holidays.add(datetime.date(YEAR, 1, 1))   # New Year
    holidays.add(datetime.date(YEAR, 7, 4))   # July 4th
    holidays.add(datetime.date(YEAR, 12, 25)) # Christmas
    holidays.add(datetime.date(YEAR, 11, 28)) # Thanksgiving (rough)
    
    # Add some vacation weeks (2-3 per year)
    vacation_weeks = random.sample(range(1, 53), 3)
    
    # First, generate the background activity pattern
    for x in range(COLS):
        for y in range(ROWS):
            date = BASE_SUNDAY + datetime.timedelta(days=x*7 + y)
            
            # Skip if not in reasonable range for the target year
            if abs(date.year - YEAR) > 1:
                continue
                
            day_of_week = date.weekday()
            is_weekend = day_of_week >= 5  # Saturday = 5, Sunday = 6
            is_holiday = date in holidays
            is_vacation_week = (date.isocalendar()[1] in vacation_weeks)
            
            # Simplified but natural activity patterns
            activity = 0
            rand = random.random()
            
            if is_holiday or is_vacation_week:
                # Holidays/vacation: mostly quiet, occasional light activity
                if rand < 0.8:
                    activity = 0
                else:
                    activity = random.randint(1, 3)
            elif is_weekend:
                # Weekends: lighter activity
                if rand < 0.4:
                    activity = 0
                elif rand < 0.8:
                    activity = random.randint(1, 8)
                else:
                    activity = random.randint(9, 15)
            else:
                # Weekdays: more consistent activity with natural variance
                if rand < 0.1:  # 10% quiet days
                    activity = random.randint(0, 2)
                elif rand < 0.4:  # 30% light days
                    activity = random.randint(3, 10)
                elif rand < 0.8:  # 40% normal days
                    activity = random.randint(11, 20)
                else:  # 20% busy days
                    activity = random.randint(21, 30)
            
            GRID[y][x] = activity
    
    # Now overlay the message with heavy emphasis (only if user explicitly set a message)
    overlay_message = MESSAGE_SET_BY_USER
    
    if overlay_message:
        print(f"🎭 Bad mode: Creating realistic activity background with message overlay: '{MESSAGE}'")
        total_width = len(MESSAGE)*5 + (len(MESSAGE)-1)  # 5-px chars + 1-px gaps
        left_pad = (COLS - total_width)//2
        top_pad  = (ROWS - 5)//2

        col = left_pad
        for ch in MESSAGE:
            if col + 5 > COLS:  # Don't overflow the grid
                break
            glyph = FONT[ch]
            for r_local, row_bits in enumerate(glyph):
                for c_local, bit in enumerate(row_bits):
                    if bit == '1' and top_pad + r_local < ROWS and col + c_local < COLS:
                        # Make message pixels VERY bright - much higher than background
                        background_activity = GRID[top_pad + r_local][col + c_local]
                        # Ensure message is always the brightest part (50+ commits above background)
                        message_activity = background_activity + random.randint(50, 80)
                        GRID[top_pad + r_local][col + c_local] = min(message_activity, 100)
            col += 6   # 5 columns of glyph + 1 column gap
        
        # Quick validation of message brightness
        message_pixels = sum(1 for x in range(COLS) for y in range(ROWS) if GRID[y][x] >= 50)
        print(f"✅ {message_pixels} high-intensity message pixels created")
    else:
        print(f"🎭 Bad mode: Creating realistic activity background without message overlay")
    
    # Show simplified activity summary
    all_commits = [GRID[y][x] for x in range(COLS) for y in range(ROWS) if GRID[y][x] > 0]
    if all_commits:
        print(f"📊 Activity: {len(all_commits)} days, Max={max(all_commits)}, Avg={sum(all_commits)/len(all_commits):.1f}")
    
else:
    # ─── 2. horizontal & vertical centering ──────────────────────────────────
    total_width = len(MESSAGE)*5 + (len(MESSAGE)-1)  # 5-px chars + 1-px gaps
    left_pad = (COLS - total_width)//2
    top_pad  = (ROWS - 5)//2

    col = left_pad
    for ch in MESSAGE:
        if col + 5 > COLS:  # Don't overflow the grid
            break
        glyph = FONT[ch]
        for r_local, row_bits in enumerate(glyph):
            for c_local, bit in enumerate(row_bits):
                if bit == '1' and top_pad + r_local < ROWS and col + c_local < COLS:
                    # Regular mode: consistent bright pixels
                    GRID[top_pad + r_local][col + c_local] = 25
        col += 6   # 5 columns of glyph + 1 column gap

# ─── 3. generate PNG preview or commit pixels ────────────────────────────────
if DRY_RUN:
    # Generate PNG visualization
    try:
        import matplotlib.pyplot as plt
        import numpy as np
        from matplotlib.colors import ListedColormap
        
        # Create a visual representation of the contribution graph
        fig, ax = plt.subplots(figsize=(15, 3))
        
        # GitHub-like color scheme
        colors = ['#161b22', '#0e4429', '#006d32', '#26a641', '#39d353']
        
        # Create the visualization grid
        visual_grid = np.zeros((ROWS, COLS))
        max_activity = max(max(row) for row in GRID) if any(any(row) for row in GRID) else 1
        
        for x in range(COLS):
            for y in range(ROWS):
                if GRID[y][x] > 0:
                    # Simplified mapping for better contrast
                    if BAD_MODE:
                        if GRID[y][x] >= 50:  # Message pixels
                            intensity = 4  # Brightest green
                        elif GRID[y][x] >= 15:
                            intensity = 3
                        elif GRID[y][x] >= 5:
                            intensity = 2
                        else:
                            intensity = 1
                    else:
                        # Regular mode: simple mapping
                        intensity = 4 if GRID[y][x] >= 20 else min(3, max(1, GRID[y][x] // 5))
                    visual_grid[y][x] = intensity
        
        # Create custom colormap
        cmap = ListedColormap(colors)
        
        # Display the grid
        im = ax.imshow(visual_grid, cmap=cmap, aspect='equal', vmin=0, vmax=4)
        
        # Remove ticks and labels
        ax.set_xticks([])
        ax.set_yticks([])
        
        # Add title
        if BAD_MODE:
            if MESSAGE_SET_BY_USER:
                title = f"Preview: '{MESSAGE}' with Heavy Activity Background for {YEAR}"
            else:
                title = f"Preview: Heavy Activity Background for {YEAR}"
        else:
            title = f"Preview: '{MESSAGE}' for {YEAR}"
        ax.set_title(title, fontsize=14, pad=20)
        
        # Add day labels (Sun, Mon, Tue, etc.)
        days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
        for i, day in enumerate(days):
            ax.text(-2, i, day, ha='right', va='center', fontsize=8)
        
        # Save the PNG
        if BAD_MODE and not MESSAGE_SET_BY_USER:
            filename = f"contribution_preview_BACKGROUND_{YEAR}.png"
        else:
            filename = f"contribution_preview_{MESSAGE}_{YEAR}.png"
        plt.tight_layout()
        plt.savefig(filename, dpi=300, bbox_inches='tight', 
                   facecolor='white', edgecolor='none')
        print(f"✅ PNG preview saved as: {filename}")
        
        # Also show summary
        active_days = sum(1 for x in range(COLS) for y in range(ROWS) if GRID[y][x] > 0)
        total_commits = sum(GRID[y][x] for x in range(COLS) for y in range(ROWS))
        
        # Calculate how many days are actually in the target year
        in_year_days = 0
        in_year_commits = 0
        if YEAR == 2008:
            BASE_SUNDAY = datetime.date(2007, 12, 30)
        else:
            base_date = datetime.date(YEAR, 1, 1)
            days_to_sunday = base_date.weekday()
            if days_to_sunday == 6:
                BASE_SUNDAY = base_date
            else:
                BASE_SUNDAY = base_date - datetime.timedelta(days=(days_to_sunday + 1) % 7)
        
        for x in range(COLS):
            for y in range(ROWS):
                if GRID[y][x] > 0:
                    date = BASE_SUNDAY + datetime.timedelta(days=x*7 + y)
                    if date.year == YEAR:
                        in_year_days += 1
                        in_year_commits += GRID[y][x]
        
        print(f"📊 Summary: {active_days} active days total, {total_commits} total commits")
        print(f"📅 In {YEAR}: {in_year_days} days, {in_year_commits} commits (others in adjacent years will be filtered out)")
        
    except ImportError:
        print("⚠️  matplotlib not available. Installing...")
        subprocess.run([sys.executable, "-m", "pip", "install", "matplotlib", "numpy"], 
                      check=True)
        print("📦 matplotlib installed. Please run the command again.")
        sys.exit(0)
        
else:
    # Calculate the base Sunday for the target year
    # Use the same logic as the original script but adapted for the target year
    if YEAR == 2008:
        # Use original calculation for 2008
        BASE_SUNDAY = datetime.date(2007, 12, 30)
    else:
        # For other years, find the Sunday before January 1st
        base_date = datetime.date(YEAR, 1, 1)
        days_to_sunday = base_date.weekday()
        if days_to_sunday == 6:  # If Jan 1 is Sunday
            BASE_SUNDAY = base_date
        else:
            # Go back to the previous Sunday
            BASE_SUNDAY = base_date - datetime.timedelta(days=(days_to_sunday + 1) % 7)

    def commit_at(day_iso, count=1):
        for i in range(count):
            # Simple file update for each commit
            with open('billboard.txt', 'w') as f:
                f.write(f"Day: {day_iso}, Commit: {i+1}/{count}, Message: {MESSAGE}\n")
            
            ts = f"{day_iso}T{12+i%12:02d}:{i%60:02d}:00"
            env = dict(os.environ, GIT_AUTHOR_DATE=ts, GIT_COMMITTER_DATE=ts)
            
            try:
                subprocess.run("git add billboard.txt && git commit -m pixel", 
                             shell=True, check=True, env=env)
            except subprocess.CalledProcessError:
                continue  # Skip failed commits

    def push_batch(force_first=False):
        """Simple batch push with fallback"""
        try:
            cmd = "git push --force-with-lease origin HEAD" if force_first else "git push --quiet origin HEAD"
            subprocess.run(cmd, shell=True, check=True)
            print("✅ Batch pushed successfully")
            return True
        except subprocess.CalledProcessError:
            try:
                subprocess.run("git push --force-with-lease origin HEAD", shell=True, check=True)
                print("✅ Recovery push successful")
                return True
            except subprocess.CalledProcessError:
                print("⚠️  Push failed - manual intervention may be required")
                return False

    total_pixels = sum(1 for x in range(COLS) for y in range(ROWS) if GRID[y][x] > 0)
    current_pixel = 0
    commits_since_push = 0
    MAX_COMMITS_PER_PUSH = 90  # Higher limit but push after completing full days
    first_push = True
    cleaned_history = os.environ.get('EXISTING_COMMITS', '0') != '0'
    super_clean_mode = os.environ.get('SUPER_CLEAN', 'false').lower() == 'true'
    
    print(f"🔄 Using smart batching: push after completing days, max {MAX_COMMITS_PER_PUSH} commits per push")
    
    if super_clean_mode:
        print("🧨 Super clean mode detected - first push will use force")
    elif cleaned_history:
        print("🧹 History cleaning detected - first push will use force")
    else:
        print("📝 Normal mode - using regular pushes")
    
    # Process pixels in chronological order (by date, not grid position)
    # This ensures we complete each day before moving to the next
    pixels_by_date = []
    for x in range(COLS):
        for y in range(ROWS):
            if GRID[y][x] > 0:
                date = BASE_SUNDAY + datetime.timedelta(days=x*7 + y)
                # STRICT: Only include dates that are actually in the target year
                if date.year == YEAR:
                    pixels_by_date.append((date, GRID[y][x]))
                else:
                    print(f"🚫 Skipping {date} (outside target year {YEAR})")
    
    # Sort by date to ensure chronological processing
    pixels_by_date.sort(key=lambda x: x[0])
    
    print(f"📅 Will create commits for {len(pixels_by_date)} days in {YEAR}")
    
    current_date = None
    commits_for_current_date = 0
    
    for i, (date, commit_count) in enumerate(pixels_by_date):
        current_pixel = i + 1
        print(f"📍 Processing pixel {current_pixel}/{total_pixels} ({date})...")
        
        # If we're starting a new date, check if we should push previous commits
        if current_date != date:
            # If we have accumulated commits and adding this day would exceed limit, push now
            if commits_since_push > 0 and (commits_since_push + commit_count) > MAX_COMMITS_PER_PUSH:
                print(f"🚀 Pushing batch ({commits_since_push} commits) before starting {date}...")
                # Use force push for first batch after super clean or history cleaning
                force_push = (first_push and (cleaned_history or super_clean_mode))
                push_batch(force_first=force_push)
                first_push = False
                commits_since_push = 0
            
            current_date = date
        
        # Create commits for this day
        commit_at(date, commit_count)
        commits_since_push += commit_count
        
        # Check if we should push after completing this day
        # Push if: we've hit the limit, OR this is the last pixel, OR next day would exceed limit
        should_push = (
            commits_since_push >= MAX_COMMITS_PER_PUSH or  # Hit the limit
            current_pixel == total_pixels or  # Last pixel
            (current_pixel < total_pixels and  # Not last pixel, but next day would exceed limit
             commits_since_push + pixels_by_date[current_pixel][1] > MAX_COMMITS_PER_PUSH)
        )
        
        if should_push:
            print(f"🚀 Pushing batch ({commits_since_push} commits) after completing {date}...")
            # Use force push for first batch after super clean or history cleaning
            force_push = (first_push and (cleaned_history or super_clean_mode))
            push_batch(force_first=force_push)
            first_push = False
            commits_since_push = 0

PY
# ----------------------------------------------------------------------------- 

if [ "$DRY_RUN" = true ]; then
    echo "🎯 Dry-run completed! No commits were made."
else
    # No need for final push since we're pushing in batches
    echo "✅ All commits pushed in batches!"
    
    if [ "$BAD_MODE" = true ]; then
        if [ "$MESSAGE_SET_BY_USER" = true ]; then
            echo "Done! View your $YEAR contributions — \"$MESSAGE\" with heavy activity background!"
        else
            echo "Done! View your $YEAR contributions — realistic heavy activity background!"
        fi
    else
        echo "Done! View your $YEAR contributions — and see \"$MESSAGE\" in the graph!"
    fi
    
    echo "ℹ️  Note: GitHub may take a few minutes to update the contribution graph"
fi

![PEEKACAT](https://github.com/user-attachments/assets/333b3d66-cd33-470a-940d-b10a12658b3f)

Peekacat can make a visit to your `2008 GitHub Contribution History` meowtooo0

---

## ⚠️ Disclaimer

**Educational Purpose Only**: This project demonstrates how GitHub contribution graphs can be inaccurate representations of a developer's actual work and productivity.

Contribution patterns can vary significantly due to various factors including:
- **Different workflow preferences** (rebasing, squashing commits, etc.)
- **Private repository work** not visible on public profiles
- **Team collaboration styles** and commit attribution
- **Project timelines and release cycles**
- **Technical constraints** and development environments

When evaluating developers, consider a broader range of indicators such as:
- **Code quality and reviews**
- **Meaningful project contributions**
- **Problem-solving abilities**
- **Collaboration and communication skills**
- **Technical knowledge and growth**

This tool serves as a reminder that contribution graphs, while interesting, don't tell the complete story of a developer's journey or capabilities.

*"The best measure of a developer's worth is not in the green squares they generate, but in the problems they solve and the value they create."*

## ⚠️ Important Notes

### History Overwriting
- When run multiple times for the same year, PEEKACAT will **overwrite** existing pixel commits from that year
- A backup tag is automatically created before any history rewriting
- Three cleaning modes for different needs:
  - **Standard**: Removes all commits from the target year only
  - **Enhanced**: Filters by both author and committer dates for thoroughness
  - **Super Clean** (`-s` flag): Completely resets the repository history for a true clean slate
- Force push (`--force-with-lease`) is used when history is rewritten

### File Updates
- The script updates and commits `billboard.txt` for each pixel to ensure real file changes
- This ensures compatibility with GitHub's contribution graph tracking
- Each commit represents one "pixel" in your contribution graph

### Batch Processing
- Commits are processed in chronological order and pushed in smart batches
- Each day's commits are completed before pushing to ensure accurate contribution counts
- Maximum 90 commits per push to optimize GitHub's processing
- This prevents the "faded lettering" issue by ensuring complete daily commit counts

### Contribution Graph Limitations

GitHub contribution graphs have inherent limitations and may not accurately reflect a developer's actual productivity or skill level.

## 🚀 Usage Examples

```bash
# Basic usage - display "HELLO" for 2020
./peekacat.sh -y 2020 -m "HELLO"

# Bad mode with message - heavy activity background with message emphasis  
./peekacat.sh --year 2023 --message "CODE" --bad

# Bad mode without message - just realistic heavy activity background
./peekacat.sh -b -y 2023

# Dry-run mode - generate PNG preview without commits
./peekacat.sh -d -m "TEST" -y 2024

# Override repository - use different repo than default
./peekacat.sh -o "username/my-repo" -m "CODE" -y 2024

# Overwrite existing year - will clean old pixel commits first
./peekacat.sh -y 2020 -m "NEW"  # Overwrites previous "HELLO" for 2020
```

## 🎨 Features

- **Custom Messages**: Display any 8-character message in your contribution graph
- **Year Selection**: Target any year, not just 2008
- **Bad Mode**: Create realistic heavy activity background 
  - With message: Overlays your message with guaranteed high visibility (50+ commits above background)
  - Without message: Creates natural-looking activity patterns with realistic variance
- **Dry-Run Mode**: Generate PNG previews without making actual commits  
- **Repository Override**: Use any GitHub repository via command-line flag
- **History Overwriting**: Safely replace existing pixel commits for the same year
- **Smart Date Calculation**: Works for any year regardless of which day January 1st falls on
- **Simplified Codebase**: Streamlined logic for better performance and maintainability

## 📝 Setup

1. Edit the `REPO` variable in the script to point to your GitHub repository
2. Make sure you have push access to the repository
3. Install matplotlib for PNG preview generation: `pip install matplotlib numpy`
4. Run the script with your desired options

## 🔧 Command-Line Options

- `-y, --year YEAR`: Target year (default: 2008)
- `-m, --message MSG`: Custom message, max 8 characters (default: PEEKACAT)  
- `-b, --bad`: Enable heavy activity background mode
  - When used with `-m`: Creates background with message overlay
  - When used alone: Creates just realistic activity background without message
- `-d, --dry-run`: Generate PNG preview without commits
- `-o, --owner-repo`: GitHub repository in OWNER/REPO format
- `-h, --help`: Show help message

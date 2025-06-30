![PEEKACAT](https://github.com/user-attachments/assets/333b3d66-cd33-470a-940d-b10a12658b3f)

Peekacat can make a visit to your `GitHub Contribution History` meowtooo0

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

*"The best measure of a developer's worth is not in the green squares they generate, but in the problems they solve and the value they create."* - @appatalks

----

## Usage

```bash
$ bash peekacat.sh -h
Usage: peekacat.sh [OPTIONS]

Generate a custom GitHub contribution graph with a message for a specified year.

OPTIONS:
    -y, --year YEAR      Target year for the contribution graph (default: 2008)
    -m, --message MSG    Custom message to display (max 8 characters, default: PEEKACAT)
    -b, --bad            Enable bad mode - creates realistic heavy activity background
                         If used with -m, overlays message on background
                         If used alone, creates just the background without message
    -d, --dry-run        Generate PNG preview without making commits
    -o, --owner-repo     GitHub repository in format OWNER/REPO (overrides REPO variable)
    -h, --help           Show this help message

EXAMPLES:
    peekacat.sh -y 2020 -m "PEEKACAT"               # Display "PEEKACAT" for 2020
    peekacat.sh --year 2023 --message "CODE" --bad  # Display "CODE" with heavy background
    peekacat.sh -b -y 2019                          # Just heavy background, no message
    peekacat.sh -d -m "TEST" -y 2024                # Preview "TEST" for 2024
    peekacat.sh -o "username/my-repo" -m "CODE" -y 2024  # Use different repo
```

----

![Screenshot from 2025-06-30 01-16-46](https://github.com/user-attachments/assets/424e530b-87a2-48de-b952-092d2cc91fbf)


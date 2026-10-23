---
description: Create a Conventional Commit using the repository's existing identity
argument-hint: "[instructions]"
---
Create a git commit for the current changes. Additional instructions: $ARGUMENTS

- Follow repository instructions, including worktree and branch restrictions.
- Inspect `git status`, staged and unstaged diffs, and recent commit history before committing. Commit only changes relevant to this task; do not include unrelated work or secrets. If the scope is unclear, ask before staging.
- Use Conventional Commits: `type(scope): description` (scope optional). Choose the appropriate type and follow the repository's existing language and scope conventions. Describe the actual changes.
- Inspect author and committer names and email addresses in recent history (for example, `git log -20 --format='%an <%ae> | %cn <%ce>'`). Reuse the established human identity; do not invent one or use a bot identity. If several identities are plausible or there is no history, ask the user.
- Set the selected name and email for both author and committer for this commit only, using `GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`, `GIT_COMMITTER_NAME`, and `GIT_COMMITTER_EMAIL`. Do not change local or global Git configuration, and do not add an AI co-author.
- Run relevant available checks. Never bypass hooks, amend an existing commit, or push unless explicitly requested. If a check or hook fails, report it rather than claiming success.
- After committing, report the commit hash, subject, identity used, and any remaining changes.

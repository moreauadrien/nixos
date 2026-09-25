# AGENTS.md

## Never work in the `main` worktree

Read-only access to `/nixos/main` is fine. Never write there: any attempt
(edit, write tool, or bash command) is hard-blocked by the
`.pi/extensions/protect-main.ts` extension and will fail with an error.
All changes go through a feature worktree (see below), then get merged
into `main` with `git merge`.

## Feature work → always use a worktree

For any new feature request, work in a dedicated `git worktree`, never on the current branch.

All `git worktree` commands must be run from `/nixos` (the bare repository), never
from inside a worktree:

```bash
cd /nixos
git worktree add feature-name
cd ./feature-name
```

Important: run the command exactly as above, **without** specifying a start point
(e.g. never `git worktree add feature-name main`). The bare `git worktree add <path>`
form creates a new branch named after the directory, based on the default branch —
which is what we want. Passing an explicit base branch (like `main`) makes git try
to check out `main`, which fails if it is already checked out in another worktree
(`fatal: 'main' is already used by worktree at ...`).

Cleanup after merge (also from `/nixos`):

```bash
cd /nixos
git worktree remove ./feature-name
git branch -d feature-name
```

Rule: one feature = one branch = one worktree. Check `git worktree list` before creating a new one.

## Worktrees → always fix the gitdir paths afterwards

The agent runs inside a container where the user's repo (`/home/adrien/nixos` on
the host) is mounted at `/nixos`. When `git worktree add` runs here, it records
**container** paths (`/nixos/...`), so on the host the new worktree's `.git`
points to a non-existent location and every `git` command there fails with
`fatal: not a git repository: (null)`.

After every `git worktree add`, rewrite the two path references to the host
layout (this is what the pre-existing worktrees like `main` use):

```bash
cd /nixos
printf '%s\n' '/home/adrien/nixos/feature-name/.git' > .git/worktrees/feature-name/gitdir
printf 'gitdir: /home/adrien/nixos/.git/worktrees/feature-name\n' > feature-name/.git
```

Verify with `git worktree list` (the new entry must show `/home/adrien/nixos/<name>`,
not `/nixos/<name>`).

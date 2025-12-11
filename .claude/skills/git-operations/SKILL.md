---
name: git
description: All git operations: commits, branches, push, pull, merge, PRs, and GitHub CLI.
---

# Git Skill

## Workflow

1. **New features**: Always create a new branch before starting work
   - Branch naming: `feature/<short-description>` or `fix/<short-description>`
   - Example: `git checkout -b feature/camera-capture`

2. **Commits**: Make atomic commits with clear messages

3. **Merging**: Use `gh` CLI to create PR and merge, then sync local main
   - `gh pr create --title "..." --body "..." --base main`
   - `gh pr merge --squash --delete-branch`
   - `git checkout main && git pull`

## Instructions

When starting a new feature:
```bash
git checkout main
git pull
git checkout -b feature/<name>
```

When feature is complete:
```bash
# 1. Commit and push
git add -A && git commit -m "..."
git push -u origin <branch>

# 2. Create PR and merge via gh
gh pr create --title "..." --body "..." --base main
gh pr merge --squash --delete-branch

# 3. Sync local main
git checkout main && git pull
```

## Rules

- Always merge via `gh pr` (not local git merge)
- Always sync local main after merging
- Never force push
- Always pull before creating new branches

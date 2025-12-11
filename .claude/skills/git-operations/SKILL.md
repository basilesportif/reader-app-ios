---
name: git-operations
description: Git workflow for feature branches and merging. Use when starting new features or completing work.
---

# Git Operations Skill

## Workflow

1. **New features**: Always create a new branch before starting work
   - Branch naming: `feature/<short-description>` or `fix/<short-description>`
   - Example: `git checkout -b feature/camera-capture`

2. **Commits**: Make atomic commits with clear messages

3. **Merging**: Always ask the user before merging branches
   - Ask: "Ready to merge `<branch>` into `main`?"
   - Wait for confirmation before proceeding

## Instructions

When starting a new feature:
```
git checkout main
git pull
git checkout -b feature/<name>
```

When feature is complete:
1. Commit all changes
2. Ask user: "Ready to merge `feature/<name>` into `main`?"
3. Only merge after user confirms:
```
git checkout main
git merge feature/<name>
git push
```

## Rules

- Never merge without asking
- Never force push
- Always pull before creating new branches

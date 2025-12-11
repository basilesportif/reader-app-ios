---
description: Create PR from current branch, squash merge to main
---

Merge the current branch into main via a GitHub PR.

Steps to follow:
1. Get the current branch name and verify it's not main
2. Check for uncommitted changes with `git status --porcelain`. If there are any:
   - Stage all changes with `git add -A`
   - Commit with a message describing the changes
   - Push to the remote branch
3. Get the list of commits on this branch (compared to main) using `git log main..HEAD --oneline`
4. Create a PR with `gh pr create`:
   - Use the first commit message as the PR title (or summarize if multiple commits)
   - Generate a summary of changes for the PR body
5. Merge the PR using `gh pr merge --squash --delete-branch`
6. Switch to main and pull the latest changes
7. Report success with the PR URL

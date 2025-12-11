Merge the current branch into main via a GitHub PR.

Steps to follow:
1. Get the current branch name and verify it's not main
2. Get the list of commits on this branch (compared to main) using `git log main..HEAD --oneline`
3. Create a PR with `gh pr create`:
   - Use the first commit message as the PR title (or summarize if multiple commits)
   - Generate a summary of changes for the PR body
4. Merge the PR using `gh pr merge --squash --delete-branch`
5. Switch to main and pull the latest changes
6. Report success with the PR URL

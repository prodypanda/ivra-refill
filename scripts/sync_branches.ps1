# scripts/sync_branches.ps1
# This script commits all pending changes to the dev-session branch,
# merges them into the local main branch, and pushes both to the remote origin.
# It is designed to prevent diverging branches and make keeping both branches in sync effortless.

param(
  [string]$CommitMessage = "chore: update app version and synchronize branches",
  [switch]$PushOnly
)

$ErrorActionPreference = "Stop"

# Get current branch name
$currentBranch = (git branch --show-current).Trim()
Write-Host "Current branch: $currentBranch"

# 1. Stage and commit changes if there are any
if (-not $PushOnly) {
  $gitStatus = git status --porcelain
  if ([string]::IsNullOrWhiteSpace($gitStatus)) {
    Write-Host "No changes to commit. Proceeding with branch synchronization..."
  } else {
    Write-Host "Changes detected. Staging all changes..."
    git add -A
    Write-Host "Committing with message: '$CommitMessage'..."
    git commit -m $CommitMessage
  }
}

# 2. Find where the 'main' branch is checked out
$worktrees = git worktree list
$mainWorktreeLine = $worktrees | Where-Object { $_ -match '\[main\]' }

if ($mainWorktreeLine) {
  # 'main' is checked out in another worktree
  $mainPath = ($mainWorktreeLine -split '\s+')[0]
  Write-Host "Branch 'main' is checked out in another worktree at: $mainPath"
  Write-Host "Performing merge and push in that worktree..."
  
  # Run merge in the main worktree
  $currentLocation = Get-Location
  try {
    Set-Location $mainPath
    Write-Host "Merging $currentBranch into main..."
    git merge $currentBranch --no-edit
    
    Write-Host "Pushing main to origin..."
    git push origin main
  }
  finally {
    Set-Location $currentLocation
  }
} else {
  # 'main' is not checked out in another worktree, we can checkout and merge here
  Write-Host "Switching to main branch..."
  git checkout main

  try {
    Write-Host "Merging $currentBranch into main..."
    git merge $currentBranch --no-edit

    Write-Host "Pushing main to origin..."
    git push origin main
  }
  finally {
    Write-Host "Switching back to $currentBranch..."
    git checkout $currentBranch
  }
}

# 3. Push development branch to origin
Write-Host "Pushing $currentBranch to origin..."
git push origin $currentBranch

Write-Host "Synchronization completed successfully! Both branches are identical and up-to-date on origin."

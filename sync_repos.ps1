# TradeVision Dual-Repo Synchronization Utility
# Pushes the latest codebase to both repositories while maintaining separate README files:
# - Personal repo (CodeWidKrish/TradeVision-AI): Single author (Krish Hingu)
# - College repo (KrishnaBhundiya/TradeVision): 3 authors (Krish Hingu, Krishna Bhundiya, Parv)

param (
    [string]$Message = ""
)

$ErrorActionPreference = "Stop"

Write-Host "`n🚀 Syncing TradeVision to both repositories..." -ForegroundColor Cyan

# Ensure we are on main
git checkout main

# If there are uncommitted changes and a message was provided, commit them
if ($Message -and (git status --porcelain)) {
    git add .
    git commit -m $Message
    Write-Host "✓ Committed changes: $Message" -ForegroundColor Green
}

# 1. Push to Personal Repository (personal/main)
Write-Host "`n📦 Pushing to Personal GitHub (CodeWidKrish/TradeVision-AI)..." -ForegroundColor Yellow
git push personal main
Write-Host "✓ Personal repository successfully updated." -ForegroundColor Green

# 2. Merge changes into college-main branch and push to College Repository (origin/main)
Write-Host "`n🏛️ Pushing to College GitHub (KrishnaBhundiya/TradeVision)..." -ForegroundColor Yellow
git checkout college-main
git merge main --no-edit -m "merge: sync latest features and fixes from main"

# Restore College README
Copy-Item README_COLLEGE.md README.md -Force
if (git status --porcelain README.md) {
    git commit -am 'docs: retain college README with 3 authors - Krish, Krishna, Parv'
}

git push origin college-main:main
Write-Host "✓ College repository successfully updated." -ForegroundColor Green

# 3. Switch back to main
git checkout main
Write-Host "`n✨ Both repositories are synchronized with their respective README files!" -ForegroundColor Cyan

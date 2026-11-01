param (
    [string]$Message = ""
)

$ErrorActionPreference = "Stop"

Write-Host "`nSyncing TradeVision to both repositories..." -ForegroundColor Cyan

git checkout main

if ($Message -ne "") {
    git add .
    git commit -m "$Message"
}

Write-Host "Pushing to Personal GitHub (CodeWidKrish/TradeVision-AI)..." -ForegroundColor Yellow
git push personal main

Write-Host "Pushing to College GitHub (KrishnaBhundiya/TradeVision)..." -ForegroundColor Yellow
git checkout college-main
git merge main --no-edit -m "merge: sync latest features and fixes from main"
Copy-Item README_COLLEGE.md README.md -Force
git add README.md
git commit -m "docs: retain college README with 3 authors" --allow-empty
git push origin college-main:main

git checkout main
Write-Host "Both repositories are synchronized!" -ForegroundColor Cyan

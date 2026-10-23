# Auto Git Push Watcher for SERN Project
Write-Host "🔄 SERN Auto-Push Watcher Started..." -ForegroundColor Cyan
Write-Host "Watching for changes in C:\sern\SERN PROJECT..." -ForegroundColor Gray

while ($true) {
    Start-Sleep -Seconds 60
    $status = git status --porcelain
    if ($status) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] Detected changes, committing and pushing to GitHub..." -ForegroundColor Yellow
        git add .
        git commit -m "auto: updates at $timestamp"
        git push origin main
        Write-Host "[$timestamp] ✅ Successfully pushed to GitHub!" -ForegroundColor Green
    }
}

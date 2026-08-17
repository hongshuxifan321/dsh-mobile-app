# apply-isloopback-patch.ps1
# Fix DSH preview limitation: remote browsers (tunnel domain) get settings degraded
# to process-local memory, so plugin config cards (Terminal / Agent Loop / Web Search)
# and the "Open Config File" button never render.
#
# Root cause: dsh-client-connection (frontend) decides connection.isLoopback from
# page location.hostname; non-loopback => settings persistence = "memory" => UI hidden.
# This script patches that check to always be true (host mode).
#
# Re-run after every DSH upgrade (upgrades overwrite node_modules).
# Usage: powershell -ExecutionPolicy Bypass -File apply-isloopback-patch.ps1
$ErrorActionPreference = 'Stop'

$target = Join-Path $HOME '.dsh\profiles\node_modules\@deepseek-ai\dsh\node_modules\@deepseek-ai\dsh-client-connection\lib\client.js'

if (-not (Test-Path $target)) {
  Write-Host "[patch] NOT FOUND: $target" -ForegroundColor Red
  Write-Host "[patch] Is DSH installed? (dsh plugin list). If the package layout changed, update this script." -ForegroundColor Yellow
  exit 1
}

$content = Get-Content $target -Raw -Encoding UTF8

if ($content -match '\[DSH Remote patch\]') {
  Write-Host '[patch] Already applied, nothing to do.' -ForegroundColor Green
  exit 0
}

$old = 'isLoopback: pageLocation === void 0 || isLoopbackHostname(pageLocation.hostname),'
if (-not $content.Contains($old)) {
  Write-Host '[patch] Target line not found (DSH version may have changed the code).' -ForegroundColor Red
  Write-Host '[patch] Manually edit the isLoopback line in:' -ForegroundColor Yellow
  Write-Host "  $target" -ForegroundColor Yellow
  exit 1
}

$new = 'isLoopback: pageLocation === void 0 || isLoopbackHostname(pageLocation.hostname) || true, // [DSH Remote patch]'
Set-Content -Path $target -Value ($content.Replace($old, $new)) -Encoding UTF8 -NoNewline
Write-Host '[patch] Applied. Restart "dsh web" to take effect.' -ForegroundColor Green
Write-Host '[patch] NOTE: re-run after every DSH upgrade.' -ForegroundColor Yellow

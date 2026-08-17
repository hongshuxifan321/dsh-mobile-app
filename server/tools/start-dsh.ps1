# start-dsh.ps1 - One-click DSH start: dsh web + cloudflared quick tunnel + fixed-domain DNS auto-sync
# The quick tunnel domain changes every restart; this script captures the new domain and
# updates YOUR fixed domain (e.g. your-domain.de5.net) via the DNSHE API, so the phone always
# uses the fixed domain. Fully configurable - see tools/dsh-config.txt.
# Usage: double-click; tunnel auto-reconnects and re-syncs DNS on every new domain.

$ErrorActionPreference = 'Continue'

# ---- single-instance guard: only one start-dsh.ps1 loop may run at a time ----
$MUTEX = New-Object System.Threading.Mutex($false, 'DSH-Remote-StartScript')
if (-not $MUTEX.WaitOne(0)) {
  Write-Host '[start-dsh] another instance is already running (single-instance lock). Exiting.' -ForegroundColor Red
  exit 1
}

$CF = 'C:\Program Files (x86)\cloudflared\cloudflared.exe'
$CONFIG = Join-Path $PSScriptRoot 'dsh-config.txt'
$LOG = Join-Path $PSScriptRoot 'quick-tunnel.log'

# ---- load config (dsh-config.txt, key=value lines) ----
$CFG = @{}
if (Test-Path $CONFIG) {
  foreach ($line in Get-Content $CONFIG) {
    $line = $line.Trim()
    if ($line -and -not $line.StartsWith('#')) {
      $p = $line.IndexOf('=')
      if ($p -gt 0) { $CFG[$line.Substring(0, $p).Trim()] = $line.Substring($p + 1).Trim() }
    }
  }
}
$SUBDOMAIN_ID = $CFG['SUBDOMAIN_ID']
$DOMAIN = $CFG['DOMAIN']
$KEY = $CFG['DNSHE_KEY']
$SECRET = $CFG['DNSHE_SECRET']
if (-not $SUBDOMAIN_ID -or -not $DOMAIN -or -not $KEY -or -not $SECRET) {
  Write-Host '[start-dsh] missing config: copy tools/dsh-config.example.txt to tools/dsh-config.txt and fill in DOMAIN / SUBDOMAIN_ID / DNSHE_KEY / DNSHE_SECRET'
  exit 1
}

function Update-Dnshe {
  param([string]$Cname)
  Write-Host ('[dns] sync {0} -> {1}' -f $DOMAIN, $Cname) -ForegroundColor Cyan
  $api = 'https://api005.dnshe.com/index.php?m=domain_hub&endpoint=dns_records'
  $hdr = @{ 'X-API-Key' = $KEY; 'X-API-Secret' = $SECRET }
  # IMPORTANT: use Invoke-RestMethod, NOT curl.exe -d. PS 5.1 strips the double
  # quotes when passing a JSON string to native exes -> server sees {type:CNAME}
  # (no quotes) -> 'invalid type'. .NET call keeps the JSON intact.
  try {
    $list = Invoke-RestMethod -Uri ($api + '&action=list&subdomain_id=' + $SUBDOMAIN_ID) -Headers $hdr -Method Get -TimeoutSec 15
  } catch {
    Write-Host ('[dns] list FAILED: ' + $_.Exception.Message) -ForegroundColor Red
    return
  }
  foreach ($r in @($list.records)) {
    try {
      $delBody = @{ record_id = $r.record_id } | ConvertTo-Json
      $del = Invoke-RestMethod -Uri ($api + '&action=delete') -Headers $hdr -Method Post -ContentType 'application/json' -Body $delBody -TimeoutSec 15
      if ($del.success) { Write-Host ('[dns] removed old {0} {1}' -f $r.type, $r.content) }
      else { Write-Host ('[dns] delete FAILED: ' + ($del.message -join ',')) -ForegroundColor Yellow }
    } catch {
      Write-Host ('[dns] delete EXCEPTION: ' + $_.Exception.Message) -ForegroundColor Yellow
    }
  }
  try {
    $createBody = @{ subdomain_id = [long]$SUBDOMAIN_ID; type = 'CNAME'; content = $Cname } | ConvertTo-Json
    $res = Invoke-RestMethod -Uri ($api + '&action=create') -Headers $hdr -Method Post -ContentType 'application/json' -Body $createBody -TimeoutSec 15
    if ($res.success) { Write-Host ('[dns] OK: ' + ($res.message -join ',')) -ForegroundColor Green }
    else { Write-Host ('[dns] create FAILED: ' + ($res.message -join ',')) -ForegroundColor Red }
  } catch {
    Write-Host ('[dns] create EXCEPTION: ' + $_.Exception.Message) -ForegroundColor Red
  }
}

# 1) ensure dsh web is running
if (-not (Get-NetTCPConnection -LocalPort 3080 -State Listen -ErrorAction SilentlyContinue)) {
  Write-Host '[start-dsh] starting dsh web...' -ForegroundColor Cyan
  Start-Process -FilePath 'cmd.exe' -ArgumentList '/c','start','dsh web' -WindowStyle Minimized
  Start-Sleep -Seconds 6
} else {
  Write-Host '[start-dsh] dsh web already running' -ForegroundColor DarkGray
}

# 1.5) ensure the isLoopback frontend patch survives DSH upgrades (idempotent:
#      already-applied -> skip; DSH changed client.js -> loud failure, no blind overwrite)
$PATCH_SCRIPT = Join-Path $PSScriptRoot 'apply-isloopback-patch.ps1'
if (Test-Path $PATCH_SCRIPT) {
  $patchOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $PATCH_SCRIPT 2>&1
  if ($LASTEXITCODE -eq 0) {
    $patchText = ($patchOut | Out-String).Trim()
    if ($patchText -match 'Already applied') {
      Write-Host '[patch] isLoopback patch OK (in place)' -ForegroundColor DarkGray
    } else {
      Write-Host "[patch] $patchText" -ForegroundColor Green
      Write-Host '[patch] just applied - restart "dsh web" so the frontend serves the patched client.js' -ForegroundColor Yellow
    }
  } else {
    Write-Host ("[patch] FAILED: " + ($patchOut | Out-String).Trim()) -ForegroundColor Red
    Write-Host '[patch] plugin config cards may be unavailable. DSH changed client.js layout? See HANDOFF pit 23' -ForegroundColor Yellow
  }
} else {
  Write-Host '[patch] apply-isloopback-patch.ps1 missing (app-android gone?), skipping patch check' -ForegroundColor DarkGray
}

# 2) quick tunnel loop: capture domain -> sync DNS -> reconnect
Write-Host '[start-dsh] starting tunnel, watching for domain...' -ForegroundColor Cyan
$lastDomain = ''
while ($true) {
  # ---- kill the tunnel this loop started last round, plus any leftover DSH tunnels ----
  if ($proc -and -not $proc.HasExited) {
    Write-Host ('[start-dsh] killing previous tunnel pid {0}' -f $proc.Id) -ForegroundColor Yellow
    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
  }
  Get-CimInstance Win32_Process -Filter "Name='cloudflared.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match 'tunnel' -and $_.CommandLine -match '--url' -and $_.CommandLine -match '8082' } |
    ForEach-Object {
      Write-Host ('[start-dsh] killing leftover tunnel pid {0}' -f $_.ProcessId) -ForegroundColor Yellow
      Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }
  Start-Sleep -Milliseconds 500

  Remove-Item $LOG -ErrorAction SilentlyContinue
  Remove-Item "$LOG.out" -ErrorAction SilentlyContinue
  $proc = Start-Process -FilePath $CF -ArgumentList 'tunnel','--url','http://127.0.0.1:8082','--protocol','http2' `
    -WindowStyle Hidden -RedirectStandardError $LOG -RedirectStandardOutput "$LOG.out" -PassThru
  $tunnelDomain = ''
  $healthTick = 0
  while (-not $proc.HasExited) {
    Start-Sleep -Milliseconds 800
    # ---- dsh web crash watchdog: ~10s tick. Check BOTH ports:
    #      3080 (dsh web) and 8082 (auth proxy - lives inside dsh web but can die
    #      silently if the plugin fails to load after a DSH upgrade). Only checking
    #      3080 would leave a dead 8082 unnoticed -> silent outage on the phone.
    $healthTick++
    if ($healthTick -ge 12) {
      $healthTick = 0
      $up3080 = [bool](Get-NetTCPConnection -LocalPort 3080 -State Listen -ErrorAction SilentlyContinue)
      $up8082 = [bool](Get-NetTCPConnection -LocalPort 8082 -State Listen -ErrorAction SilentlyContinue)
      if (-not $up3080 -or -not $up8082) {
        Write-Host ('[start-dsh] dsh web(3080:' + $up3080 + ') proxy(8082:' + $up8082 + ') not healthy, restarting...') -ForegroundColor Yellow
        Start-Process -FilePath 'cmd.exe' -ArgumentList '/c','start','dsh web' -WindowStyle Minimized
        Start-Sleep -Seconds 6
      }
    }
    if (Test-Path $LOG) {
      $txt = Get-Content $LOG -Raw -ErrorAction SilentlyContinue
      if ($txt) {
        $m = [regex]::Match($txt, 'https://([a-z0-9-]+\.trycloudflare\.com)')
        if ($m.Success) {
          $tunnelDomain = $m.Groups[1].Value
          if ($tunnelDomain -ne $lastDomain) {
            Update-Dnshe -Cname $tunnelDomain
            $lastDomain = $tunnelDomain
            # Real tunnel domains live only in tools/last-phone-url.txt (runtime,
            # gitignored). The fixed domain (your-domain.de5.net) is initialized once
            # in ~/.dsh/mobile-remote.auth - no per-tunnel maintenance needed.
            $phoneUrl = 'https://' + $tunnelDomain
            Write-Host ('[start-dsh] PHONE URL: ' + $phoneUrl + ' (fixed domain https://' + $DOMAIN + ' when DNSHE is healthy)') -ForegroundColor Green
            # persist current phone URL (autostart runs hidden - user reads this file)
            Set-Content -Path (Join-Path $PSScriptRoot 'last-phone-url.txt') -Value $phoneUrl -Encoding ASCII
          }
        }
      }
    }
  }
  Write-Host '[start-dsh] tunnel disconnected, retry in 3s...' -ForegroundColor Yellow
  Start-Sleep -Seconds 3
}

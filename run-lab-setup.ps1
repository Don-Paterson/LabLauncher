# run-lab-setup.ps1
# Master launcher for Check Point lab automation scripts.
# Usage:  irm https://raw.githubusercontent.com/Don-Paterson/LabLauncher/main/run-lab-setup.ps1 | iex
#
# Presents a flat checklist of available scripts. Toggle items by number,
# then press Enter to run them sequentially (default) or in parallel (-Parallel).
#
# Adding a new script: append an entry to the $Scripts array below.

param(
    [switch]$Parallel
)

# ── Script registry ──────────────────────────────────────────────────────────
# Each entry: Name (menu label), Desc (one-liner), Url (irm target)
$Scripts = @(
    @{
        Name = 'UK Locale / Timezone Setup'
        Desc = 'Patches Skillable VMs to UK keyboard, GMT timezone, en-GB locale'
        Url  = 'https://raw.githubusercontent.com/Don-Paterson/SkillableMods/main/run-uk-setup.ps1'
    }
    @{
        Name = 'SmartConsole Cleanup'
        Desc = 'Removes legacy SmartConsole versions (R77.30-R81.20), keeps R82'
        Url  = 'https://raw.githubusercontent.com/Don-Paterson/SmartConsoleCleanup/main/run-cleanup.ps1'
    }
    @{
        Name = 'MobaXterm Install + Sessions'
        Desc = 'Installs MobaXterm via winget and injects lab SSH bookmarks'
        Url  = 'https://raw.githubusercontent.com/Don-Paterson/MobaXterm-Setup/main/run-mobaxterm-setup.ps1'
    }
    @{
        Name = 'chkp-monitor Deploy'
        Desc = 'Bootstraps the Check Point health-monitoring dashboard'
        Url  = 'https://raw.githubusercontent.com/Don-Paterson/chkp-monitor/main/bootstrap.ps1'
    }
    @{
        Name = 'Plink Automation Runner'
        Desc = 'GUI tool for running clish commands across lab gateways via plink'
        Url  = 'https://raw.githubusercontent.com/Don-Paterson/Plink-Automation/main/run-plink-automation.ps1'
    }
)

# ── Colours & helpers ────────────────────────────────────────────────────────
function Write-Header {
    Write-Host ''
    Write-Host '  ╔══════════════════════════════════════════════════╗' -ForegroundColor Cyan
    Write-Host '  ║        Check Point Lab Setup Launcher           ║' -ForegroundColor Cyan
    Write-Host '  ╚══════════════════════════════════════════════════╝' -ForegroundColor Cyan
    Write-Host ''
}

function Show-Menu {
    param([bool[]]$Selected)

    for ($i = 0; $i -lt $Scripts.Count; $i++) {
        $marker = if ($Selected[$i]) { '[X]' } else { '[ ]' }
        $color  = if ($Selected[$i]) { 'Green' } else { 'Gray' }
        Write-Host "  $marker " -ForegroundColor $color -NoNewline
        Write-Host "$($i + 1). " -ForegroundColor White -NoNewline
        Write-Host "$($Scripts[$i].Name)" -ForegroundColor Yellow -NoNewline
        Write-Host " - $($Scripts[$i].Desc)" -ForegroundColor DarkGray
    }
    Write-Host ''
    Write-Host '  Commands:  ' -NoNewline -ForegroundColor DarkGray
    Write-Host '<number>' -ForegroundColor White -NoNewline
    Write-Host ' toggle  |  ' -ForegroundColor DarkGray -NoNewline
    Write-Host 'A' -ForegroundColor White -NoNewline
    Write-Host ' select all  |  ' -ForegroundColor DarkGray -NoNewline
    Write-Host 'N' -ForegroundColor White -NoNewline
    Write-Host ' select none  |  ' -ForegroundColor DarkGray -NoNewline
    Write-Host 'Enter' -ForegroundColor White -NoNewline
    Write-Host ' run  |  ' -ForegroundColor DarkGray -NoNewline
    Write-Host 'Q' -ForegroundColor White -NoNewline
    Write-Host ' quit' -ForegroundColor DarkGray
    Write-Host ''
}

# ── Main menu loop ───────────────────────────────────────────────────────────
$selected = [bool[]]::new($Scripts.Count)

Clear-Host
Write-Header

while ($true) {
    Show-Menu -Selected $selected

    $input_raw = Read-Host '  Selection'
    $choice = $input_raw.Trim()

    if ($choice -eq 'Q' -or $choice -eq 'q') {
        Write-Host '  Cancelled.' -ForegroundColor DarkGray
        return
    }
    if ($choice -eq 'A' -or $choice -eq 'a') {
        for ($i = 0; $i -lt $selected.Count; $i++) { $selected[$i] = $true }
        Clear-Host; Write-Header; continue
    }
    if ($choice -eq 'N' -or $choice -eq 'n') {
        for ($i = 0; $i -lt $selected.Count; $i++) { $selected[$i] = $false }
        Clear-Host; Write-Header; continue
    }
    if ($choice -eq '') {
        # Enter pressed — run selected scripts
        break
    }

    # Toggle by number (supports "1 3 5" or "1,3,5" or just "2")
    $nums = $choice -split '[,\s]+' | Where-Object { $_ -match '^\d+$' }
    $valid = $false
    foreach ($n in $nums) {
        $idx = [int]$n - 1
        if ($idx -ge 0 -and $idx -lt $Scripts.Count) {
            $selected[$idx] = -not $selected[$idx]
            $valid = $true
        }
    }
    if (-not $valid) {
        Write-Host "  Invalid input: '$choice'" -ForegroundColor Red
    }
    Clear-Host
    Write-Header
}

# ── Execution ────────────────────────────────────────────────────────────────
$toRun = @()
for ($i = 0; $i -lt $Scripts.Count; $i++) {
    if ($selected[$i]) { $toRun += $Scripts[$i] }
}

if ($toRun.Count -eq 0) {
    Write-Host '  Nothing selected.' -ForegroundColor DarkGray
    return
}

$mode = if ($Parallel) { 'PARALLEL' } else { 'SEQUENTIAL' }
Write-Host ''
Write-Host "  Running $($toRun.Count) script(s) [$mode]..." -ForegroundColor Cyan
Write-Host '  ────────────────────────────────────────────' -ForegroundColor DarkGray

if ($Parallel) {
    # Launch each in its own PowerShell process
    $jobs = @()
    foreach ($script in $toRun) {
        Write-Host "  Starting: $($script.Name)" -ForegroundColor Yellow
        $jobs += Start-Process powershell.exe -ArgumentList @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command',
            "irm '$($script.Url)' | iex"
        ) -PassThru
    }
    Write-Host ''
    Write-Host "  $($jobs.Count) process(es) launched." -ForegroundColor Green
    Write-Host '  Each runs in its own window. Close them when done.' -ForegroundColor DarkGray
}
else {
    # Sequential — run each in the current session
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $successes = 0
    $failures  = 0

    foreach ($script in $toRun) {
        Write-Host ''
        Write-Host "  ▶ $($script.Name)" -ForegroundColor Yellow
        Write-Host "    $($script.Url)" -ForegroundColor DarkGray
        try {
            $scriptContent = Invoke-RestMethod -Uri $script.Url -UseBasicParsing -ErrorAction Stop
            Invoke-Expression $scriptContent
            $successes++
            Write-Host "  ✓ $($script.Name) completed." -ForegroundColor Green
        }
        catch {
            $failures++
            Write-Host "  ✗ $($script.Name) FAILED: $_" -ForegroundColor Red
        }
    }

    $stopwatch.Stop()
    Write-Host ''
    Write-Host '  ════════════════════════════════════════════' -ForegroundColor Cyan
    Write-Host "  Done. $successes succeeded, $failures failed. [$([math]::Round($stopwatch.Elapsed.TotalSeconds, 1))s]" -ForegroundColor Cyan
}

# run-lab-setup.ps1
# Master launcher for Check Point lab automation scripts.
# Usage:  irm https://raw.githubusercontent.com/Don-Paterson/LabLauncher/main/run-lab-setup.ps1 | iex
#
# WinForms GUI: tick the scripts you want, optionally check "Run in parallel",
# then click Run. Sequential mode shows progress in the output pane.
# Parallel mode launches each script in its own PowerShell window.
#
# Adding a new script: append an entry to the $Scripts array below.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

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

# ── Build UI ─────────────────────────────────────────────────────────────────
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Check Point Lab Setup Launcher'
$form.Size = New-Object System.Drawing.Size(620, 520)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

# Script checklist label
$lblScripts = New-Object System.Windows.Forms.Label
$lblScripts.Text = 'Select scripts to run:'
$lblScripts.Location = New-Object System.Drawing.Point(12, 12)
$lblScripts.AutoSize = $true
$lblScripts.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblScripts)

# Checklist — shows "Name - Desc" for each script
$clb = New-Object System.Windows.Forms.CheckedListBox
$clb.Location = New-Object System.Drawing.Point(12, 36)
$clb.Size = New-Object System.Drawing.Size(580, 175)
$clb.CheckOnClick = $true
$clb.Font = New-Object System.Drawing.Font('Segoe UI', 9)
foreach ($s in $Scripts) {
    [void]$clb.Items.Add("$($s.Name)  —  $($s.Desc)")
}
$form.Controls.Add($clb)

# Select All / Select None buttons
$btnAll = New-Object System.Windows.Forms.Button
$btnAll.Text = 'Select All'
$btnAll.Location = New-Object System.Drawing.Point(12, 218)
$btnAll.Size = New-Object System.Drawing.Size(90, 28)
$form.Controls.Add($btnAll)
$btnAll.Add_Click({
    for ($i = 0; $i -lt $clb.Items.Count; $i++) { $clb.SetItemChecked($i, $true) }
})

$btnNone = New-Object System.Windows.Forms.Button
$btnNone.Text = 'Select None'
$btnNone.Location = New-Object System.Drawing.Point(110, 218)
$btnNone.Size = New-Object System.Drawing.Size(90, 28)
$form.Controls.Add($btnNone)
$btnNone.Add_Click({
    for ($i = 0; $i -lt $clb.Items.Count; $i++) { $clb.SetItemChecked($i, $false) }
})

# Parallel checkbox
$chkParallel = New-Object System.Windows.Forms.CheckBox
$chkParallel.Text = 'Run in parallel (each script in its own window)'
$chkParallel.Location = New-Object System.Drawing.Point(14, 256)
$chkParallel.AutoSize = $true
$chkParallel.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$form.Controls.Add($chkParallel)

# Run and Close buttons
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = 'Run'
$btnRun.Location = New-Object System.Drawing.Point(12, 286)
$btnRun.Size = New-Object System.Drawing.Size(100, 32)
$btnRun.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($btnRun)

$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text = 'Close'
$btnClose.Location = New-Object System.Drawing.Point(120, 286)
$btnClose.Size = New-Object System.Drawing.Size(80, 32)
$form.Controls.Add($btnClose)
$btnClose.Add_Click({ $form.Close() })

# Output log
$lblOutput = New-Object System.Windows.Forms.Label
$lblOutput.Text = 'Output:'
$lblOutput.Location = New-Object System.Drawing.Point(12, 326)
$lblOutput.AutoSize = $true
$lblOutput.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblOutput)

$txtOutput = New-Object System.Windows.Forms.TextBox
$txtOutput.Location = New-Object System.Drawing.Point(12, 348)
$txtOutput.Size = New-Object System.Drawing.Size(580, 125)
$txtOutput.Multiline = $true
$txtOutput.ScrollBars = 'Vertical'
$txtOutput.ReadOnly = $true
$txtOutput.Font = New-Object System.Drawing.Font('Consolas', 9)
$form.Controls.Add($txtOutput)

# ── Run logic ────────────────────────────────────────────────────────────────
$btnRun.Add_Click({
    # Collect selected scripts
    $toRun = @()
    for ($i = 0; $i -lt $clb.Items.Count; $i++) {
        if ($clb.GetItemChecked($i)) { $toRun += $Scripts[$i] }
    }

    if ($toRun.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            'Please select at least one script.',
            'Nothing selected',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    # Disable UI while running
    $btnRun.Enabled      = $false
    $btnClose.Enabled    = $false
    $btnAll.Enabled      = $false
    $btnNone.Enabled     = $false
    $clb.Enabled         = $false
    $chkParallel.Enabled = $false

    $txtOutput.Clear()
    $txtOutput.AppendText("Starting at $([DateTime]::Now)`r`n")
    $txtOutput.AppendText("Scripts: $($toRun.ForEach({ $_.Name }) -join ', ')`r`n`r`n")

    if ($chkParallel.Checked) {
        # ── Parallel: each in its own window ──
        # Use the same PS edition that launched us (pwsh.exe or powershell.exe)
        $psExe = (Get-Process -Id $PID).Path
        $jobs = @()
        foreach ($s in $toRun) {
            $txtOutput.AppendText("Launching: $($s.Name)`r`n")
            $jobs += Start-Process $psExe -ArgumentList @(
                '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command',
                "irm '$($s.Url)' | iex; Write-Host ''; Write-Host 'Press any key to close...'; `$null = `$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')"
            ) -PassThru
        }
        $txtOutput.AppendText("`r`n$($jobs.Count) window(s) launched. Close them when done.`r`n")
    }
    else {
        # ── Sequential: run in current session ──
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $successes = 0
        $failures  = 0

        foreach ($s in $toRun) {
            $txtOutput.AppendText(">> $($s.Name)`r`n")
            $form.Refresh()
            try {
                $scriptContent = Invoke-RestMethod -Uri $s.Url -UseBasicParsing -ErrorAction Stop
                Invoke-Expression $scriptContent
                $successes++
                $txtOutput.AppendText("   OK`r`n`r`n")
            }
            catch {
                $failures++
                $txtOutput.AppendText("   FAILED: $_`r`n`r`n")
            }
            $form.Refresh()
        }

        $stopwatch.Stop()
        $elapsed = [math]::Round($stopwatch.Elapsed.TotalSeconds, 1)
        $txtOutput.AppendText("Done. $successes succeeded, $failures failed. [${elapsed}s]`r`n")
    }

    # Re-enable UI
    $btnRun.Enabled      = $true
    $btnClose.Enabled    = $true
    $btnAll.Enabled      = $true
    $btnNone.Enabled     = $true
    $clb.Enabled         = $true
    $chkParallel.Enabled = $true
})

# ── Show ─────────────────────────────────────────────────────────────────────
[void]$form.ShowDialog()

# LabLauncher

Single entry point for all Check Point lab automation scripts. Run one command at the start of a Skillable lab session, tick the scripts you want, and click Run.

## Quick start

Open any PowerShell session:

```
irm https://raw.githubusercontent.com/Don-Paterson/LabLauncher/main/run-lab-setup.ps1 | iex
```

A GUI window appears with a checklist of available scripts. Tick the ones you need, optionally check "Run in parallel", and click **Run**.

## What it does

1. Presents a WinForms checklist of all registered automation scripts
2. **Select All** / **Select None** buttons for quick toggling
3. **Run in parallel** checkbox — launches each selected script in its own PowerShell window
4. Sequential mode (default) runs each script in the current session with success/failure tracking and elapsed time
5. Output pane shows real-time progress

## Available scripts

| # | Script | Description | Source |
|---|--------|-------------|--------|
| 1 | UK Locale / Timezone Setup | Patches Skillable VMs to UK keyboard, GMT timezone, en-GB locale | [SkillableMods](https://github.com/Don-Paterson/SkillableMods) |
| 2 | SmartConsole Cleanup | Removes legacy SmartConsole versions (R77.30–R81.20), keeps R82 | [SmartConsoleCleanup](https://github.com/Don-Paterson/SmartConsoleCleanup) |
| 3 | MobaXterm Install + Sessions | Installs MobaXterm via winget and injects lab SSH bookmarks | [MobaXterm-Setup](https://github.com/Don-Paterson/MobaXterm-Setup) |
| 4 | chkp-monitor Deploy | Bootstraps the Check Point health-monitoring dashboard | [chkp-monitor](https://github.com/Don-Paterson/chkp-monitor) |
| 5 | Plink Automation Runner | GUI tool for running clish commands across lab gateways via plink | [Plink-Automation](https://github.com/Don-Paterson/Plink-Automation) |

## Adding a new script

Append an entry to the `$Scripts` array in `run-lab-setup.ps1`:

```powershell
@{
    Name = 'My New Script'
    Desc = 'Short description of what it does'
    Url  = 'https://raw.githubusercontent.com/Don-Paterson/<repo>/main/<entry-point>.ps1'
}
```

No other changes needed — the checklist rebuilds from the array automatically.

## Typical lab workflow

On **RDP-HOST** at lab start, run the launcher and tick UK Locale Setup and SmartConsole Cleanup, check "Run in parallel", and click Run. Five minutes later on **A-GUI**, run the launcher again and tick SmartConsole Cleanup, MobaXterm Install, chkp-monitor Deploy, and Plink Automation, then run sequentially.

## Requirements

* PowerShell 5.1 or later
* Internet access to GitHub raw content

## Related

* [SkillableMods](https://github.com/Don-Paterson/SkillableMods) — UK locale/timezone patching for Skillable lab VMs
* [SmartConsoleCleanup](https://github.com/Don-Paterson/SmartConsoleCleanup) — removes legacy SmartConsole versions
* [MobaXterm-Setup](https://github.com/Don-Paterson/MobaXterm-Setup) — silent MobaXterm install with lab session injection
* [chkp-monitor](https://github.com/Don-Paterson/chkp-monitor) — Check Point health-monitoring dashboard
* [Plink-Automation](https://github.com/Don-Paterson/Plink-Automation) — GUI runner for clish commands via plink

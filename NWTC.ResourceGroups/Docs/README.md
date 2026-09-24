# NWTC.ResourceGroups

## Purpose

`NWTC.ResourceGroups` is a PowerShell module for creating Azure test resource groups with consistent naming, tagging, and logging. It packages the `New-TestResourceGroup` function so it can be loaded, versioned, and shared the same way on every system instead of passing script copies around.

The module is the starting point for the Cloud Operations Team's resource group tooling. Commands for resource group reporting, auditing, and lifecycle management are planned for later versions.

## Features

- **Two ways to name a resource group:** by project ID (`1001` becomes `RG-1001`) or by full name.
- **Multiple values:** accepts a comma-separated list (`-ProjectID 1017, 1018`) or pipeline input, including bulk input from a file.
- **Skips existing groups:** checks Azure first, so a bulk run never stalls on an "update existing group?" prompt.
- **Safe to preview:** supports `-WhatIf` and `-Confirm`.
- **Input validation:** project IDs must be digits; names allow only letters, numbers, hyphens, and underscores. One bad value rejects the whole command before anything is created.
- **Structured output:** returns one object per request with a `Created`, `Skipped`, or `Failed` status.
- **Run summary:** shows total, created, skipped, and error counts plus elapsed time.
- **Per-run log files:** every run writes a timestamped log to the module's `Logs` folder through a private helper.

## Requirements

- PowerShell 7.0 or later
- The Az PowerShell module (`Az.Resources` provides `Get-AzResourceGroup` and `New-AzResourceGroup`)
- An authenticated Azure session:

```powershell
Connect-AzAccount -TenantId "mh4372.onmicrosoft.com"
```

## Installation

### Option 1: Import from the repository

Good for testing or one-off use.

```powershell
git clone https://github.com/XxInquisitorxX07/powershell-advanced-mike.git
Import-Module .\powershell-advanced-mike\NWTC.ResourceGroups\NWTC.ResourceGroups.psd1
```

### Option 2: Install for the current user

Copies the module into a folder PowerShell searches automatically (`$env:PSModulePath`), so it can be imported by name from any directory. The version number is part of the path, which lets multiple versions sit side by side.

Run from the root of the cloned repository:

```powershell
$dest = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules\NWTC.ResourceGroups\1.0.0'
New-Item -ItemType Directory -Path $dest -Force | Out-Null
Copy-Item -Path .\NWTC.ResourceGroups\* -Destination $dest -Recurse -Force
Import-Module NWTC.ResourceGroups
```

### Confirm the install

```powershell
Get-Module NWTC.ResourceGroups | Select-Object Name, Version, Path
Get-Command -Module NWTC.ResourceGroups
```

Only `New-TestResourceGroup` should be listed. The logging helper is private.

## Usage

**Create by project ID (creates `RG-1001`):**

```powershell
New-TestResourceGroup -ProjectID 1001
```

**Create by full name:**

```powershell
New-TestResourceGroup -ResourceGroupName Dev1
```

**Several at once:**

```powershell
New-TestResourceGroup -ProjectID 1017, 1018
New-TestResourceGroup -ResourceGroupName Dev3, Dev4
"1001", "1002", "1003" | New-TestResourceGroup
```

**Bulk from a file (one project ID per line):**

```powershell
Get-Content .\lab-files\ResourceGroups.txt | New-TestResourceGroup
```

**Preview without creating anything:**

```powershell
Get-Content .\lab-files\ResourceGroups.txt | New-TestResourceGroup -WhatIf
```

**Custom tags:**

```powershell
New-TestResourceGroup -ProjectID 1001 -Tags @{Department="Dev"; Environment="Development"}
```

**Save and report on results:**

```powershell
$results = Get-Content .\lab-files\ResourceGroups.txt | New-TestResourceGroup
$results | Group-Object Status | Select-Object Name, Count
```

**Full help:**

```powershell
Get-Help New-TestResourceGroup -Full
```

## Logging

Each run creates one log file in the module's `Logs` folder:

```text
Logs\New-TestResourceGroup-Log-yyyyMMdd-HHmmss.txt
```

Example contents:

```text
2026-09-24 09:07:58 [INFO] Starting the creation of Resource Group... (parameter set: ProjectID)
2026-09-24 09:07:58 [INFO] Creating Resource Group based on ProjectID: 1015
2026-09-24 09:07:58 [INFO] Creating Resource Group 'RG-1015' in 'centralus'
2026-09-24 09:08:00 [INFO] Resource Group 'RG-1015' created successfully.
2026-09-24 09:08:02 [WARN] Resource Group 'RG-1001' already exists. Skipping.
2026-09-24 09:08:02 [INFO] Finished processing the creation of Resource Group. Total: 3, Created: 2, Skipped: 1, Errors: 0
```

Levels are `INFO`, `WARN`, and `ERROR`. Logging still happens during `-WhatIf`, so dry runs leave a record too. The log location is tied to the module folder, not the current directory. If the module is installed with Option 2, logs are written to the installed copy's `Logs` folder.

## Module Structure

```text
NWTC.ResourceGroups
│   NWTC.ResourceGroups.psd1    Manifest: version, author, exports, metadata
│   NWTC.ResourceGroups.psm1    Loader: dot-sources Public and Private, exports Public only
├───Docs
│       README.md               This file
├───Logs                        Per-run log files (not tracked in Git)
├───Private
│       Write-ModuleLog.ps1     Internal logging helper (not exported)
├───Public
│       New-TestResourceGroup.ps1
└───Tests                       Reserved for module Pester tests
```

### Adding a new command

1. Create one `.ps1` file in `Public`, named exactly after the function it contains.
2. Add the function name to `FunctionsToExport` in `NWTC.ResourceGroups.psd1`.
3. Increase `ModuleVersion` (see below).
4. Re-import with `Import-Module .\NWTC.ResourceGroups.psd1 -Force`.

Internal helpers go in `Private` and are loaded automatically but never exported.

## Version Information

Check the loaded version:

```powershell
Get-Module NWTC.ResourceGroups | Select-Object Name, Version
```

The module uses semantic versioning (`Major.Minor.Patch`):

- **Patch** – bug fixes only, safe to update.
- **Minor** – new features; existing commands work the same.
- **Major** – breaking changes; test existing scripts before updating.

| Version | Date | Changes |
| --- | --- | --- |
| 1.0.0 | 2026-09-24 | Initial release: `New-TestResourceGroup` with ProjectID and ResourceGroupName parameter sets, array and pipeline input, skip check, `-WhatIf`/`-Confirm`, structured output, run summary, and per-run logging through the private `Write-ModuleLog` helper. |

## Known Limitations

- Location is fixed to `centralus`.
- The `Tests` folder is empty. The existing Pester tests in `create-resourcegroup/` test the older standalone script, not this module.
- Each public `.ps1` file must be named after its function. The loader uses the file name to decide what to export.

## Author

Mike Hagel – PowerShell Advanced, NWTC
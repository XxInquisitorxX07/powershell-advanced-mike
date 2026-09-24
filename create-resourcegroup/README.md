# New-TestResourceGroup

An advanced PowerShell function that creates Azure Resource Groups. It supports two ways of naming resource groups, comma-separated and pipeline input for bulk creation, skipping groups that already exist, structured output, verbose progress messages, per-run log files, and an end-of-run summary.

## Where the Function Lives

As of LM5, the current version of this function is part of the **NWTC.ResourceGroups** module:

```text
NWTC.ResourceGroups\Public\New-TestResourceGroup.ps1
```

The `create-resourcegroup.ps1` file in this folder is the standalone LM4 version. It is kept because the Pester tests in this folder are written against it. It does not include the LM5 changes (module logging and array parameters).

Module installation and packaging details are in `NWTC.ResourceGroups/Docs/README.md`.

## Requirements

- PowerShell 7 or later
- The Az PowerShell module
- An authenticated Azure session
- Pester 5 or later (for running the tests)

```powershell
Connect-AzAccount -TenantId "mh4372.onmicrosoft.com"
```

## Loading the Function

Import the module. Run this again with `-Force` after every change to the module files.

```powershell
Import-Module .\NWTC.ResourceGroups\NWTC.ResourceGroups.psd1 -Force
```

Confirm it loaded from the module:

```powershell
Get-Command New-TestResourceGroup | Select-Object Name, Version, Source
```

## Parameters

The function has two parameter sets. Only one can be used at a time, and PowerShell rejects a command that uses both.

| Parameter | Parameter Set | Details |
| --- | --- | --- |
| `ProjectID` | ProjectID (default) | Mandatory in its set. One or more values, digits only. Each resource group name is generated as `RG-<ProjectID>`. Accepts input from the pipeline. |
| `ResourceGroupName` | ResourceGroupName | Mandatory in its set. One or more full resource group names. Only letters, numbers, hyphens, and underscores are allowed. |
| `Tags` | Both | Optional hashtable of tags. Defaults to `@{Department="IT"; Environment="Test"}`. Custom tags replace the defaults rather than merging with them. |

`ProjectID` is the default parameter set, so a piped value like `"1001"` is treated as a project ID.

Validation checks every value in a list. If any value fails, the whole command is rejected before anything is created.

The function also supports the common parameters through `[CmdletBinding()]`, including `-Verbose`, `-Debug`, and `-ErrorAction`, plus `-WhatIf` and `-Confirm` through `SupportsShouldProcess`.

## Usage

**By project ID (creates `RG-1001`):**

```powershell
New-TestResourceGroup -ProjectID 1001
```

**By full name:**

```powershell
New-TestResourceGroup -ResourceGroupName Dev1
```

**Several at once (comma-separated):**

```powershell
New-TestResourceGroup -ProjectID 1017, 1018
New-TestResourceGroup -ResourceGroupName Dev3, Dev4
```

**Multiple project IDs from the pipeline:**

```powershell
"1001","1002","1003" | New-TestResourceGroup
```

**Bulk creation from a file (one project ID per line, no blank lines):**

```powershell
Get-Content .\lab-files\ResourceGroups.txt | New-TestResourceGroup
```

**With custom tags:**

```powershell
New-TestResourceGroup -ProjectID 1001 -Tags @{Department="Dev";Environment="Development"}
```

**Preview without creating anything:**

```powershell
Get-Content .\lab-files\ResourceGroups.txt | New-TestResourceGroup -WhatIf
```

**Show step-by-step progress:**

```powershell
New-TestResourceGroup -ProjectID 1001 -Verbose
```

## How Each Request Is Handled

Every request ends with exactly one result:

1. **Skipped.** The resource group already exists (checked with `Get-AzResourceGroup`), or `-WhatIf` was used, or `-Confirm` was declined. Existing groups also produce a warning.
2. **Created.** `New-AzResourceGroup` finished without errors.
3. **Failed.** Azure returned an error. The error is caught, and the Azure message is shown with `Write-Warning`, so the rest of the run keeps going.

## Output

The function returns a `PSCustomObject` for each request:

| Property | Description |
| --- | --- |
| ResourceGroupName | The final resource group name |
| Location | Always `centralus` |
| Status | `Created`, `Skipped`, or `Failed` |
| Tags | The hashtable of tags applied |
| Timestamp | When the request was processed |

Only result objects come out of the output stream. Startup messages and the run summary use `Write-Host`, warnings use `Write-Warning`, and logging writes straight to a file, so saved results can be counted, filtered, or exported cleanly.

```powershell
$results = Get-Content .\lab-files\ResourceGroups.txt | New-TestResourceGroup
$results | Group-Object Status | Select-Object Name, Count
$results | Export-Csv .\results.csv -NoTypeInformation
```

## Run Summary

When all requests are finished, the `end` block displays a summary:

```text
===== Run Summary =====
Total requests processed : 3
Created successfully     : 2
Skipped                  : 1
Errors                   : 0
Elapsed time             : 4.4 seconds
```

Created, Skipped, and Errors always add up to the total.

## Verbose Messages

Running with `-Verbose` shows labeled messages for each step:

| Label | Where | Meaning |
| --- | --- | --- |
| `[START]` | `begin` | Function started, with the parameter set and log file path |
| `[VALIDATION]` | `process` | Input passed validation and the final name was determined |
| `[ATTEMPT]` | `process` | Creation is starting |
| `[SUCCESS]` | `process` | The resource group was created |
| `[SKIPPED]` | `process` | Creation was blocked by `-WhatIf` or `-Confirm` |
| `[COMPLETE]` | `end` | All requests are finished, with the log file path |

## Logging

Each run writes one log file to the module's `Logs` folder through the private `Write-ModuleLog` helper:

```text
NWTC.ResourceGroups\Logs\New-TestResourceGroup-Log-yyyyMMdd-HHmmss.txt
```

Each line has a timestamp and a level (`INFO`, `WARN`, or `ERROR`):

```text
2026-09-24 09:08:02 [WARN] Resource Group 'RG-1001' already exists. Skipping.
```

The path is built from `$PSScriptRoot`. Inside the function that points to the `Public` folder, so the function goes up one level with `Split-Path -Parent` to reach the module root. Logs land in the same place no matter what directory the function is called from.

Logging uses `-WhatIf:$false -Confirm:$false`, so `-WhatIf` runs are still logged and only resource group creation is controlled by `-WhatIf` and `-Confirm`.

This replaced the `Start-Transcript`/`Stop-Transcript` logging used through LM4.

## Testing

Pester tests are in `create-resourcegroup.tests.ps1`. The Azure cmdlets are mocked, so the tests do not create real resources and do not need an Azure connection.

```powershell
Invoke-Pester .\create-resourcegroup\create-resourcegroup.tests.ps1 -Output Detailed
```

These tests cover the **standalone LM4 version** in this folder:

- Both parameter sets, and rejection when both are used together
- Pipeline input with multiple project IDs
- Output containing only result objects
- Skipping existing resource groups
- Handling Azure errors
- `-WhatIf` not creating anything
- Parameter validation for both parameters

The module version was tested manually in LM5 (both parameter sets, comma-separated and pipeline input, bulk file input, validation, log content, and log location). Moving the Pester tests into `NWTC.ResourceGroups\Tests` to run against the module is planned.

## Notes

Author: Mike Hagel
Course: PowerShell Advanced
# New-TestResourceGroup

An advanced PowerShell function that creates Azure Resource Groups. It supports two ways of naming resource groups, bulk creation through the pipeline, skipping groups that already exist, structured output, verbose progress messages, and an end-of-run summary.

## Requirements

- PowerShell 7 or later
- The Az PowerShell module
- An authenticated Azure session
- Pester 5 or later (for running the tests)

```powershell
Connect-AzAccount -TenantId "mh4372.onmicrosoft.com"
```

## Loading the Function

The file only defines the function. It has to be dot-sourced to load the definition into the session before the function can be called. Run this again after every change to the file.

```powershell
. .\create-resourcegroup\create-resourcegroup.ps1
```

## Parameters

The function has two parameter sets. Only one can be used at a time, and PowerShell rejects a command that uses both.

| Parameter | Parameter Set | Details |
| --- | --- | --- |
| `ProjectID` | ProjectID (default) | Mandatory in its set. Digits only. The resource group name is generated as `RG-<ProjectID>`. Accepts input from the pipeline. |
| `ResourceGroupName` | ResourceGroupName | Mandatory in its set. The full name of the resource group. Only letters, numbers, hyphens, and underscores are allowed. |
| `Tags` | Both | Optional hashtable of tags. Defaults to `@{Department="IT"; Environment="Test"}`. Custom tags replace the defaults rather than merging with them. |

`ProjectID` is the default parameter set, so a piped value like `"1001"` is treated as a project ID.

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

**With custom tags:**

```powershell
New-TestResourceGroup -ProjectID 1001 -Tags @{Department="Dev";Environment="Development"}
```

**Multiple project IDs from the pipeline:**

```powershell
"1001","1002","1003" | New-TestResourceGroup
```

**Bulk creation from a file (one project ID per line, no blank lines):**

```powershell
Get-Content .\lab-files\ResourceGroups.txt | New-TestResourceGroup
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
3. **Failed.** Azure returned an error. The error is caught, and the Azure message is shown with `Write-Warning`, so the rest of the pipeline keeps running.

## Output

The function returns a `PSCustomObject` for each request:

| Property | Description |
| --- | --- |
| ResourceGroupName | The final resource group name |
| Location | Always `centralus` |
| Status | `Created`, `Skipped`, or `Failed` |
| Tags | The hashtable of tags applied |
| Timestamp | When the request was processed |

Only result objects come out of the output stream. Startup messages and the run summary use `Write-Host`, warnings use `Write-Warning`, and transcript messages are sent to `Out-Null`, so saved results can be counted, filtered, or exported cleanly.

```powershell
$results = Get-Content .\lab-files\ResourceGroups.txt | New-TestResourceGroup
$results | Group-Object Status | Select-Object Name, Count
$results | Export-Csv .\output\results.csv -NoTypeInformation
```

## Run Summary

When all requests are finished, the `end` block displays a summary:

```text
===== Run Summary =====
Total requests processed : 2
Created successfully     : 1
Skipped                  : 1
Errors                   : 0
Elapsed time             : 1.9 seconds
```

Created, Skipped, and Errors always add up to the total.

## Verbose Messages

Running with `-Verbose` shows labeled messages for each step:

| Label | Where | Meaning |
| --- | --- | --- |
| `[START]` | `begin` | Function started, with the parameter set and log path |
| `[VALIDATION]` | `process` | Input passed validation and the final name was determined |
| `[ATTEMPT]` | `process` | Creation is starting |
| `[SUCCESS]` | `process` | The resource group was created |
| `[SKIPPED]` | `process` | Creation was blocked by `-WhatIf` or `-Confirm` |
| `[COMPLETE]` | `end` | All requests are finished |

## Logging

Every run is appended to a transcript in the `output` folder at the root of the repository. The path is built with `$PSScriptRoot`, so it resolves to the same location no matter what directory the function is called from.

```powershell
Start-Transcript -Path $logPath -Append -WhatIf:$false -Confirm:$false | Out-Null
```

The transcript commands use `-WhatIf:$false -Confirm:$false`, so only resource group creation is controlled by `-WhatIf` and `-Confirm`.

## Testing

Pester tests are in `create-resourcegroup.tests.ps1`. The Azure cmdlets are mocked, so the tests do not create real resources and do not need an Azure connection.

```powershell
Invoke-Pester .\create-resourcegroup\create-resourcegroup.tests.ps1 -Output Detailed
```

The tests cover:

- Both parameter sets, and rejection when both are used together
- Pipeline input with multiple project IDs
- Output containing only result objects
- Skipping existing resource groups
- Handling Azure errors
- `-WhatIf` not creating anything
- Parameter validation for both parameters

## Notes

Author: Mike Hagel
Course: PowerShell Advanced
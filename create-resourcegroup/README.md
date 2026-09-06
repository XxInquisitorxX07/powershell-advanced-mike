# New-TestResourceGroup
An advanced PowerShell function that creates an Azure Resource Group with optional tags, pipeline support, and structured output.
## Requirements
- PowerShell 7 or later
- The Az PowerShell module
- An authenticated Azure session
```powershell
Connect-AzAccount -TenantId "mh4372.onmicrosoft.com"
```
## Loading the Function
The file only defines the function. It has to be dot-sourced to load the definition into the session before the function can be called.
```powershell
. .\create-resourcegroup.ps1
```
## Parameters
**ResourceGroupName** - Mandatory. The name of the resource group to create. Accepts input from the pipeline. Validated with `ValidatePattern` so only letters, numbers, hyphens, and underscores are allowed.

**Tags** - Optional. A hashtable of tags to apply to the resource group. Defaults to `@{Department="IT"; Environment="Test"}`. Supplying custom tags replaces the defaults rather than merging with them.

The function also supports the common parameters through `[CmdletBinding()]`, including `-Verbose`, `-Debug`, and `-ErrorAction`, plus `-WhatIf` and `-Confirm` through `SupportsShouldProcess`.
## Usage
**Basic:**
```powershell
New-TestResourceGroup -ResourceGroupName "MyResourceGroup"
```
**With custom tags:**
```powershell
New-TestResourceGroup -ResourceGroupName "DevTest" -Tags @{Department="Dev";Environment="Development"}
```
**From the pipeline:**
```powershell
"DevTest1","DevTest2" | New-TestResourceGroup
```
**Preview without creating anything:**
```powershell
"DevTest" | New-TestResourceGroup -WhatIf
```
**Prompt before creating:**
```powershell
"DevTest" | New-TestResourceGroup -Confirm
```
## Output
The function returns a `PSCustomObject` for each resource group with the following properties:

| Property | Description |
| --- | --- |
| ResourceGroupName | The name of the resource group |
| Location | Always `centralus` |
| Status | `Created` on success, `Not Created` on failure or when skipped |
| Tags | The hashtable of tags applied |
| Timestamp | When the attempt was made |

Because the output is an object rather than text, the results can be filtered, sorted, selected, or exported without parsing.
```powershell
"Test1","Test2" | New-TestResourceGroup | Select-Object ResourceGroupName, Status
```
Errors are written to the warning stream with `Write-Warning` so only objects come out of the output stream.
## Logging
Every run writes a transcript to the `output` folder at the root of the repository. The path is built with `$PSScriptRoot` so it resolves to the same location no matter what directory the function is called from.
```powershell
Start-Transcript -Path (Join-Path $PSScriptRoot "..\output\create-resourcegroup.log.txt") -WhatIf:$false -Confirm:$false
```
The transcript commands are set to `-WhatIf:$false -Confirm:$false` so that only the resource group creation is governed by `-WhatIf` and `-Confirm`.
## Testing
Pester tests for the function are in `create-resourcegroup.tests.ps1`.
```powershell
Invoke-Pester .\create-resourcegroup.tests.ps1
```
## Notes
Author: Mike Hagel
Course: PowerShell Advanced
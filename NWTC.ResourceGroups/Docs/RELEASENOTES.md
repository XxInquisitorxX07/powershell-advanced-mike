# NWTC.ResourceGroups 1.1.0 Release Notes

**Release date:** 2026-10-03
**Release type:** Minor (new feature, backward compatible)
**Previous version:** 1.0.0 (2026-09-24)

## New Features

**Get-ResourceGroupSummary.** A quick, read-only report of your resource groups.

```powershell
Get-ResourceGroupSummary                          # all resource groups
Get-ResourceGroupSummary -Name 'RG-1001','Dev1'   # specific groups
'RG-1001' | Get-ResourceGroupSummary              # from the pipeline
Get-ResourceGroupSummary | Where-Object Tags -ne 'None' | Format-Table
```

Returns `ResourceGroupName`, `Location`, and `Tags` (shown as `Key=Value; Key=Value`, or `None`). A name that doesn't exist produces a warning and the rest still run.

**Module test suite.** `Tests/NWTC.ResourceGroups.Tests.ps1` holds 13 Pester tests. Run them with:

```powershell
Invoke-Pester -Path .\NWTC.ResourceGroups\Tests -Output Detailed
```

All Azure calls are mocked, so the tests create nothing.

## Bug Fixes

None in this release. `New-TestResourceGroup` is unchanged from 1.0.0.

## Upgrade Instructions

1. Get the new version: `git pull`, or extract `Releases/NWTC.ResourceGroups1.1.0.zip`.
2. Unload the old version, which PowerShell keeps in memory:
   `Remove-Module NWTC.ResourceGroups -ErrorAction SilentlyContinue`
3. Import the new one:
   `Import-Module <path>\NWTC.ResourceGroups\NWTC.ResourceGroups.psd1 -Force`
4. Confirm:
   - `Get-Module NWTC.ResourceGroups` should show Version **1.1.0**
   - `Get-Command -Module NWTC.ResourceGroups` should list both functions
5. Connect to Azure before use:
   `Connect-AzAccount -TenantId "mh4372.onmicrosoft.com"`

No changes are needed to existing scripts that call `New-TestResourceGroup`.

## Known Issues

- Location is hardcoded to `centralus` in `New-TestResourceGroup`. There is no `-Location` parameter yet.
- The LM4 Pester tests for `New-TestResourceGroup` still target the standalone script copy in `create-resourcegroup/` and have not been ported into the module `Tests` folder.
- `Get-ResourceGroupSummary` returns tags as a flattened string. Scripts that need the raw hashtable should use `Get-AzResourceGroup`.
- Requires the `Az.Resources` module and an active Azure session. Signing into the wrong tenant gives misleading "no permission" errors.
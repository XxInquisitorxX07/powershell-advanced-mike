# LM6 Lab: Managing the Lifecycle of a PowerShell Module

**Author:** Mike Hagel
**VM:** PA-mike
**Module:** NWTC.ResourceGroups
**Goal:** Prepare, document, test, and package version 1.1.0

---

## Task 1: Baseline (v1.0.0)

| Field | Value |
|---|---|
| Current Version | 1.0.0 |
| Author | Mike Hagel |
| Description | Test resource group creation |
| Exported Commands | New-TestResourceGroup |

Captured with:

    $manifest = Test-ModuleManifest .\NWTC.ResourceGroups\NWTC.ResourceGroups.psd1
    $manifest | Select-Object Name, Version, Author, Description
    $manifest.ExportedFunctions.Keys

Notes:
- `Write-ModuleLog` is a private helper. The loader dot-sources it but does not export it, which is correct.
- The `.psm1` loader picks up every `.ps1` in `Public\` and exports each one by file name, so new public functions only need a matching file name and a `FunctionsToExport` entry in the manifest.
- Known gaps going into LM6: the module `Tests` folder is empty (only `.gitkeep`), and the location is hardcoded to `centralus`.

## Task 2: New Feature - Get-ResourceGroupSummary

- Added `Public/Get-ResourceGroupSummary.ps1`. It returns ResourceGroupName, Location, and Tags for one, many, or all resource groups.
- Tags are flattened to `Key=Value; Key=Value` (sorted by key). Untagged groups show `None`.
- Accepts names by parameter or pipeline (by value, or by the `ResourceGroupName` property), so `New-TestResourceGroup` output can be piped straight in.
- A missing group produces a `[NOT FOUND]` warning and processing continues.
- Read-only, so no ShouldProcess is needed.
- The `.psm1` loader picked up the new file automatically. The manifest still had to be updated: `FunctionsToExport` now lists both functions. Without that entry the function would not be exported.

Verification:

| Test | Result |
|---|---|
| `Get-Command -Module NWTC.ResourceGroups` | Get-ResourceGroupSummary and New-TestResourceGroup listed; Write-ModuleLog stays private |
| `Get-ResourceGroupSummary` | 42 resource groups returned with name, location, and tags |
| `-Name 'RG-1001','Dev1'` | Both returned |
| `'RG-1001' \| Get-ResourceGroupSummary` | Pipeline input works |
| `-Name 'DoesNotExist'` | `[NOT FOUND]` warning, no crash |
| Created `LM6-Test` with tags, then summarized it | `Owner=Mike; Project=LM6` |

## Task 3: Semantic Versioning - 1.0.0 → 1.1.0

Updated `ModuleVersion` in `NWTC.ResourceGroups.psd1` to `1.1.0` and added `ReleaseNotes` to the manifest's PSData section. Re-imported with `-Force`. `Get-Command -Module NWTC.ResourceGroups` now shows both functions at version 1.1.0.

**Why this is a MINOR release:**
Semantic versioning is MAJOR.MINOR.PATCH. This release adds new functionality (`Get-ResourceGroupSummary`) without changing anything that already existed. `New-TestResourceGroup` keeps the same name, parameters, and output, so any script written against 1.0.0 still works on 1.1.0. That backward-compatible addition is the definition of a minor bump.

- **Not a patch (1.0.1):** patches are only for backward-compatible bug fixes. This release adds a feature.
- **Not a major (2.0.0):** nothing was removed or renamed, and no parameter or output change breaks existing scripts.

**Testing added:**
The module `Tests` folder now holds `NWTC.ResourceGroups.Tests.ps1`, with 13 Pester tests:
- Module checks: valid manifest, version 1.1.0, both functions exported, `Write-ModuleLog` stays private, help exists.
- Get-ResourceGroupSummary: all groups, output properties, tag formatting, untagged groups, pipeline by value and by property, missing-group warning.
- `Get-AzResourceGroup` is mocked with `Mock -ModuleName NWTC.ResourceGroups`, because the call happens inside the module. No Azure resources are touched.

Result: `Tests Passed: 13, Failed: 0, Skipped: 0` (Pester v6.1.0, 3.06s)


## Task 4: Changelog

Created `NWTC.ResourceGroups/Docs/CHANGELOG.md` following the Keep a Changelog format, with the newest version on top.

- **1.1.0 (2026-10-03):** Added Get-ResourceGroupSummary, updated documentation, and improved testing (13-test Pester suite), plus the changelog, release notes, and release package.
- **1.0.0 (2026-09-24):** Initial release. The date was pulled from git history with `git log --diff-filter=A --format=%as -- NWTC.ResourceGroups/NWTC.ResourceGroups.psd1`.

Entries are grouped under **Added** and **Changed**, so an administrator can see what's new versus what was modified without reading the code. The changelog is the permanent history of the module. Each version gets an entry, and old entries are never removed.


## Task 5: Release Notes

Created `NWTC.ResourceGroups/Docs/RELEASENOTES.md` covering:

- **New Features:** Get-ResourceGroupSummary, with usage examples, and the 13-test Pester suite.
- **Bug Fixes:** none in this release. It is stated honestly rather than left blank.
- **Upgrade Instructions:** pull or extract, `Remove-Module` the old version, `Import-Module -Force` the new one, confirm 1.1.0 with `Get-Module` and `Get-Command`, then connect to the correct tenant.
- **Known Issues:** hardcoded `centralus` location, LM4 tests not yet ported into the module, tags returned as a flattened string, and the Az/tenant requirement.

Changelog vs. release notes: the changelog is the running history of every version. The release notes are written for the people upgrading to *this* version: what's new, how to upgrade safely, and what to watch out for.


## Task 6: Upgrade Test Results

Started clean with `Remove-Module`, then `Import-Module -Force`. That proves 1.1.0 loads fresh, rather than a 1.0.0 copy left in the session.

| Check | Command | Result |
|---|---|---|
| Module loads | `Import-Module .\NWTC.ResourceGroups\NWTC.ResourceGroups.psd1 -Force` | No errors |
| Version | `Get-Module NWTC.ResourceGroups` | 1.1.0, loaded from `C:\powershell-advanced-mike\NWTC.ResourceGroups` |
| Exports | `Get-Command -Module NWTC.ResourceGroups` | Get-ResourceGroupSummary and New-TestResourceGroup, both 1.1.0 |
| New feature | `Get-ResourceGroupSummary -Name 'RG-1001','Dev1','LM6-Test'` | All 3 returned with correct tags |
| Missing group | `Get-ResourceGroupSummary -Name 'DoesNotExist'` | `[NOT FOUND]` warning, no crash |
| Regression | `New-TestResourceGroup -ProjectID 9999 -WhatIf` | "What if" message, Status Skipped, nothing created |
| Tests | `Invoke-Pester -Path .\NWTC.ResourceGroups\Tests` | 13 passed, 0 failed (1.08s) |

Sample output:

```
ResourceGroupName Location  Tags
----------------- --------  ----
RG-1001           centralus Department=IT; Environment=Test
Dev1              centralus Department=IT; Environment=Test
LM6-Test          centralus Owner=Mike; Project=LM6
```

The regression check matters as much as testing the new feature. A minor release promises that existing functionality is unchanged, and running `New-TestResourceGroup` after the upgrade proves that promise was kept.
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
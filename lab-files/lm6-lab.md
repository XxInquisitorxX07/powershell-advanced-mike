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
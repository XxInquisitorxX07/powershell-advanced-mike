# LM5 Lab Journal – Converting Functions into a PowerShell Module

**Module:** NWTC.ResourceGroups
**Function:** New-TestResourceGroup
**Environment:** PA-mike VM, VS Code, PowerShell 7.6.5, Az module
**Tenant:** mh4372.onmicrosoft.com

---

## Task 1 – Create a Module Structure

**What I did**
- Created the `NWTC.ResourceGroups` folder with `Public`, `Private`, `Tests`, `Logs`, and `Docs` subfolders.
- Created an empty `NWTC.ResourceGroups.psm1`.
- Copied `create-resourcegroup.ps1` into `Public` as `New-TestResourceGroup.ps1` (copy, not move – the LM4 file and its Pester test still work).
- Created `lab-files/lm5-lab.md`.
- Added `NWTC.ResourceGroups/Logs/*.txt` to `.gitignore` so log files stay out of the repo.

**Commands**
```powershell
New-Item -ItemType Directory -Path NWTC.ResourceGroups\Public, NWTC.ResourceGroups\Private, NWTC.ResourceGroups\Tests, NWTC.ResourceGroups\Logs, NWTC.ResourceGroups\Docs
New-Item -ItemType File -Path NWTC.ResourceGroups\NWTC.ResourceGroups.psm1
New-Item -ItemType File -Path NWTC.ResourceGroups\Private\.gitkeep, NWTC.ResourceGroups\Tests\.gitkeep, NWTC.ResourceGroups\Logs\.gitkeep, NWTC.ResourceGroups\Docs\.gitkeep
Copy-Item .\create-resourcegroup\create-resourcegroup.ps1 .\NWTC.ResourceGroups\Public\New-TestResourceGroup.ps1
Add-Content -Path .gitignore -Value "NWTC.ResourceGroups/Logs/*.txt"
```

**Result**
- Commit `16f53ef` "Initial commit" – 8 files pushed.

**Notes**
- Git tracks files, not folders. Empty folders don't get pushed, so each empty folder got a `.gitkeep` placeholder file.
- Running the `.gitkeep` command a second time throws "already exists" errors – harmless, the files were already there.

---

## Task 2 – Create a Script Module

**What I did**
- Wrote the loader in `NWTC.ResourceGroups.psm1`. It finds every `.ps1` in `Public` and dot-sources it inside the module.
- Imported the module and confirmed the function comes from it.

**Key code**
```powershell
$publicFunctions = Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue
foreach ($file in $publicFunctions) {
    . $file.FullName
}
```

**Verification**
```powershell
Import-Module .\NWTC.ResourceGroups.psm1 -Force
Get-Module NWTC.ResourceGroups
Get-Command New-TestResourceGroup | Select-Object Name, Source
```
- `Get-Module` showed `NWTC.ResourceGroups`, version `0.0`, exporting `New-TestResourceGroup`.
- `Source` = `NWTC.ResourceGroups` – the function came from the module, not an old dot-sourced copy.

**Result**
- Commit `a95115b` "Add module loader to NWTC.ResourceGroups.psm1".

**Notes**
- The lab hint says `$PSScriptPath` – that variable doesn't exist. The correct one is `$PSScriptRoot`.
- `$PSScriptRoot` is the folder the `.psm1` lives in, so the path works no matter where `Import-Module` is run from.
- `Import-Module -Force` replaces the old edit → save → dot-source routine. Without `-Force`, PowerShell keeps the old version loaded.
- Version shows `0.0` because there's no manifest yet (Task 3).
- The function was exported even without `Export-ModuleMember` – a `.psm1` exports every function by default (Task 4 will control this).

---

## Task 3 – Create a Module Manifest

**What I did**
- Generated `NWTC.ResourceGroups.psd1` with `New-ModuleManifest`.
- Validated the manifest and imported the module through it.

**Command**
```powershell
New-ModuleManifest -Path .\NWTC.ResourceGroups.psd1 -RootModule 'NWTC.ResourceGroups.psm1' -Author 'Mike Hagel' -ModuleVersion '1.0.0' -Description 'Test resource group creation'
```

**Verification**
```powershell
Test-ModuleManifest .\NWTC.ResourceGroups.psd1
Remove-Module NWTC.ResourceGroups -ErrorAction SilentlyContinue
Import-Module .\NWTC.ResourceGroups.psd1 -Force
Get-Module NWTC.ResourceGroups
```
- `Test-ModuleManifest` passed with no errors, version `1.0.0`. `ExportedCommands` was blank – that's expected. It only reads the `.psd1` and never runs the `.psm1`, and `FunctionsToExport = '*'` doesn't name any commands for it to list.
- `Get-Module` after a real import shows version `1.0.0` (was `0.0` in Task 2) and exports `New-TestResourceGroup`.

**Result**
- Commit `d327d02` "Add module manifest NWTC.ResourceGroups.psd1 (v1.0.0)".

**Notes**
- The lab example leaves out `-RootModule`. Without it, the manifest has no code file to load – importing the `.psd1` gives version `1.0.0` but zero commands. Added it so the module can be imported through the manifest (needed for the Task 7 install instructions).
- `Remove-Module` before the import clears the Task 2 copy so the result proves the manifest works, not a leftover.
- `GUID` was generated automatically. It uniquely identifies this module even if another module has the same name.
- Ran `New-ModuleManifest` twice by accident. The second run silently overwrote the first, including a new `GUID`. Harmless before the first commit, but on a published module regenerating the manifest would change its identity.
- `FunctionsToExport = '*'` is the default in the manifest. Left it for now – Task 4 controls exports with `Export-ModuleMember`.
- The `.psm1` holds the code; the `.psd1` holds the metadata (version, author, description, what to load).
- Lab doc typos: "NWTC.ReourceGroups" in Task 3, and the description is worded two ways ("resource groups creation" vs. "resource group creation"). Used the example's wording.

---

## Task 4 – Export Module Members

**What I did**
- Added `Export-ModuleMember` to the end of `NWTC.ResourceGroups.psm1` so only functions from the `Public` folder are exported.

**Key code**
```powershell
Export-ModuleMember -Function $publicFunctions.BaseName
```

**Verification**
```powershell
Import-Module .\NWTC.ResourceGroups.psd1 -Force
Get-Command -Module NWTC.ResourceGroups
```
- Output listed only `New-TestResourceGroup`, version `1.0.0`, source `NWTC.ResourceGroups`.

**Result**
- Commit `ac61208` "Export public functions with Export-ModuleMember".

**Notes**
- Without `Export-ModuleMember`, a `.psm1` exports every function it loads. Once it's used, only the listed functions are exported – this is what will keep the Task 5 private helper hidden.
- `$publicFunctions.BaseName` is the file name without `.ps1`. It only works because each file is named after the function inside it – one function per file.
- The manifest's `FunctionsToExport = '*'` doesn't override this. The `.psm1` decides what gets exported, and the manifest can only narrow that list further.
- Had to re-import with `-Force` for the change to show up.

---

## Task 5 – Create a Private Helper Function

**What I did**
- Created `Private\Write-ModuleLog.ps1` – a helper that writes timestamped lines to a log file.
- Updated `NWTC.ResourceGroups.psm1` to load the `Private` folder too, without exporting it.
- Replaced `Start-Transcript`/`Stop-Transcript` in `New-TestResourceGroup` with `Write-ModuleLog` calls.
- Removed `Private\.gitkeep` with `git rm` now that the folder has a real file.

**Write-ModuleLog parameters**
- `-Message` (mandatory) – text to log.
- `-LogFile` (mandatory) – full path to the log file.
- `-Level` – `INFO`, `WARN`, or `ERROR` (`ValidateSet`), defaults to `INFO`.
- Extras: creates the log folder if it's missing; uses `-WhatIf:$false -Confirm:$false` on `New-Item` and `Add-Content` so logging still happens during `-WhatIf`.

**Log format**
```
2026-09-24 09:00:17 [INFO] Starting the creation of Resource Group... (parameter set: ProjectID)
2026-09-24 09:00:17 [INFO] Creating Resource Group based on ProjectID: 1001
2026-09-24 09:00:24 [WARN] Resource Group 'RG-1001' already exists. Skipping.
2026-09-24 09:00:24 [INFO] Finished processing the creation of Resource Group. Total: 1, Created: 0, Skipped: 1, Errors: 0
```

**Verification**
- Tested `Write-ModuleLog` alone by dot-sourcing it: INFO and WARN lines written correctly; `-Level DEBUG` was rejected by `ValidateSet`. Removed the test copy with `Remove-Item Function:\Write-ModuleLog` so it couldn't affect the module test.
- After re-import, `Get-Command -Module NWTC.ResourceGroups` still shows only `New-TestResourceGroup`.
- `Get-Command Write-ModuleLog` returns "not recognized" – the helper is loaded inside the module but hidden from users.
- `New-TestResourceGroup -ProjectID 1001` logged the `[WARN]` skip (RG-1001 already exists).
- `New-TestResourceGroup -ProjectID 1013 -WhatIf` logged "not performed (WhatIf or Confirm declined)" – logging works during `-WhatIf`.
- Logs landed in `NWTC.ResourceGroups\Logs\`; `Test-Path .\Public\Logs` = `False`.

**Result**
- Commit `171dc8e` "Add private Write-ModuleLog helper function".
- Commit `066d28d` "Load private functions and replace transcript with Write-ModuleLog".

**Notes**
- Log path problem: inside a function, `$PSScriptRoot` is the folder of the file the function is defined in – for `New-TestResourceGroup` that's `Public`, not the module root. Without a fix, logs would go to `Public\Logs`. Fixed with `Split-Path -Path $PSScriptRoot -Parent` to go up one level.
- Private functions are loaded (dot-sourced) so public functions can call them, but `Export-ModuleMember` only lists `$publicFunctions.BaseName`, so they stay hidden.
- Same ShouldProcess lesson as the LM3 transcript: `-WhatIf` flows into every command the function calls, so the helper needs `-WhatIf:$false` or `-WhatIf` would also skip logging.
- One log file per run, named with the start time (`New-TestResourceGroup-Log-yyyyMMdd-HHmmss.txt`). `.gitignore` keeps them out of the repo.
- The 7-second gap between "Creating" and "already exists" in the RG-1001 log is the `Get-AzResourceGroup` call to Azure.
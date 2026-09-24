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
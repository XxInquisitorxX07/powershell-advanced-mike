# LM3 Lab
## Task 1: Create Your First Advanced Function
**What changed:** The original script was converted into an advanced function named `New-TestResourceGroup` by wrapping the entire body in a function block and adding `[CmdletBinding()]` above the param block.

**How the script is used now:**
```powershell
. .\create-resourcegroup.ps1
New-TestResourceGroup -ResourceGroupName "LM3Test1" -Verbose
```
**Observation:** Running the file no longer creates a resource group. It only loads the function definition into memory, and the function has to be called by name afterward. `[CmdletBinding()]` also added the common parameters, so `-Verbose`, `-Debug`, and `-ErrorAction` work without writing them into the param block.
## Task 2: Add Parameter Validation
**Parameter added:**
```powershell
[hashtable]$Tags = @{
    Department  = "IT"
    Environment = "Test"
}
```
**Comparison to ResourceGroupName:** `ResourceGroupName` is mandatory, is a string, and uses `ValidatePattern` to reject invalid characters. `Tags` is optional, is a hashtable, and has a default value. A parameter cannot be both mandatory and have a default value, since those mean opposite things.

**Test using custom tags:**
```powershell
New-TestResourceGroup -ResourceGroupName "DevTest" -Tags @{Department="Dev";Environment="Development"}
```
**Observation:** Passing custom tags replaces the defaults completely instead of merging with them. The resource group came back with Department set to Dev and Environment set to Development, with no trace of the default values.
## Task 3: Accept Pipeline Input
**Parameter attribute added:**
```powershell
[Parameter(
    Mandatory,
    ValueFromPipeline = $true
)]
```
**Test with multiple objects:**
```powershell
"PipeTest2","PipeTest3" | New-TestResourceGroup
```
**Result:** Two resource groups were created, wrapped by a single transcript start and stop.
### Issue: Process Block Required
The function body had to be split into `begin`, `process`, and `end` blocks. Without a `process` block, the entire body is treated as an `end` block, which runs once after the pipeline finishes and only uses the last value that came through. Piping in two names would have created one resource group with no error message, so the missing one would have been easy to miss. Splitting the code also keeps `Start-Transcript` in `begin` so it only runs once no matter how many names are piped in.
## Task 4: Create Structured Output
**Object returned:**
```powershell
$result = [PSCustomObject]@{
    ResourceGroupName = $ResourceGroupName
    Location          = 'centralus'
    Status            = 'Not Created'
    Tags              = $Tags
    Timestamp         = Get-Date
}
```
**Test:**
```powershell
"ObjTest1","ObjTest2" | New-TestResourceGroup | Select-Object ResourceGroupName, Status, Timestamp
```
**Observation:** The status starts as Not Created and is only changed to Created after the Azure command succeeds, so the object still reports honestly if creation fails or is skipped. Returning an object instead of a string means the results can be filtered, sorted, or exported without having to pull information out of a sentence. The `Write-Output` messages were removed and the error message was changed to `Write-Warning` so only objects come out of the output stream.
## Task 5: Add WhatIf Support
**CmdletBinding changed to:**
```powershell
[CmdletBinding(SupportsShouldProcess = $true)]
```
**Test using WhatIf:**
```
PS C:\powershell-advanced-mike\LM1> "WhatIfTest2" | New-TestResourceGroup -WhatIf
What if: Performing the operation "Create" on target "Resource Group 'WhatIfTest2'".

ResourceGroupName : WhatIfTest2
Location          : centralus
Status            : Not Created
Tags              : {[Department, IT], [Environment, Test]}
Timestamp         : 9/6/2026 5:53:15 PM
```
### Issue: WhatIf and Confirm Propagate Into Called Commands
The first `-WhatIf` run also produced "What if" messages for `Start-Transcript` and `Stop-Transcript`, even though only the Azure call was wrapped in `ShouldProcess`. The switch flows into every command called inside the function that supports it, the same way `-Debug` did in LM2.

Adding `-WhatIf:$false` to the transcript commands fixed the `-WhatIf` run but not the `-Confirm` run, because the two switches are independent. Both had to be set explicitly:
```powershell
Start-Transcript -Path (Join-Path $PSScriptRoot "..\output\create-resourcegroup.log.txt") -WhatIf:$false -Confirm:$false
```
**Observation:** `-Confirm` still produced an extra prompt from `New-AzResourceGroup` itself when the resource group already existed. That prompt comes from the Az module's own `ShouldProcess` implementation, not from my function.
## Task 6: Repository Reorganization
**New structure:**
```
powershell-advanced-mike/
    create-resourcegroup/
        create-resourcegroup.ps1
        create-resourcegroup.tests.ps1
        README.md
    lab-files/
        lm1-lab.md
        lm2-lab.md
        lm3-lab.md
    output/
        create-resourcegroup.log.txt
    README.md
```
The folders were renamed with `git mv` instead of File Explorer so Git recorded the moves as renames and kept the file history.
### Issue: Transcript Path
The transcript used a relative path, which resolves against the working directory at the time the function is called rather than the location of the script. This caused a misplaced log file in LM1 and LM2, and it broke completely once the script moved into its own folder and transcripts moved to the `output` folder.

**Fix:**
```powershell
Start-Transcript -Path (Join-Path $PSScriptRoot "..\output\create-resourcegroup.log.txt") -WhatIf:$false -Confirm:$false
```
`$PSScriptRoot` points to the folder the script file lives in, not the working directory, so the path resolves the same way no matter where the function is called from.

**Test from two different directories:**
```
PS C:\powershell-advanced-mike\create-resourcegroup> New-TestResourceGroup -ResourceGroupName "PathTest1"
Transcript stopped, output file is C:\powershell-advanced-mike\output\create-resourcegroup.log.txt

PS C:\powershell-advanced-mike> New-TestResourceGroup -ResourceGroupName "PathTest2"
Transcript stopped, output file is C:\powershell-advanced-mike\output\create-resourcegroup.log.txt
```
**Observation:** Both runs wrote to the same file even though the working directories were different. This fixed the transcript path issue that had been showing up since LM1.
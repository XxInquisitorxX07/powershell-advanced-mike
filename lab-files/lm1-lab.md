# LM1 Lab

## Task 1 Evaluate Script
```powershell
$a = Read-Host "RG Name"

New-AzResourceGroup -Name $a -Location centralus
```

### Issue 1: No input Validation
**Problem:** A problem would be that it will accept whatever the user enters or if leaves it empty and will send it straight to azure.

**Impact:** This could lead to unorganized naming conventions within the company guidelines or standards.

### Issue 2: Undeclared dependencies
**Problem:** This script needs to ensure the Az module is installed and has an active authenticated Azure session, but it doesnt decalre neither requirement.

**Impact:** This would end up leaving people to think that they completed their setups without any verification being done; which could lead to more downtime to do a clean up and/or deleting and readding.

### Issue 3: Requires interactive input
**Problem:** Read-host halts and waits for a human at the keyboard.

**Impact:** This is something requires input, it cannot be scheduled or called by another script. It requires an administrator to be present so any automation doesn't scale.

## Task 2: Create Professional Documentation
**Purpose of the script:** Creates a new Azure Resource Group. This script creates a new Azure Resource Group with the specified name and location.

**Parameter documented:** ResourceGroupName - The name of the Resource Group to create.

**Verification:** Ran 'Get-Help .\create-resourcegroup.ps1' and confiremed the synopsis, description, and example were returned

**Sample execution example:**
```powershell
.\create-resourcegroup.ps1 -ResourceGroupName "MyResourceGroup"
```
## Task 3: Implement Parameter Validation
**Validation method selected:** ValidatePattern, using `^[a-zA-Z0-9-_]+$`

**Why:** Azure resource group names only allow certain characters. This pattern requires every character to be a letter, number, hyphen, or underscore, so bad names are rejected before the script contacts Azure.

**Example of valid input:** `.\create-resourcegroup.ps1 -ResourceGroupName "myRG1"`

**Example of invalid input:** `.\create-resourcegroup.ps1 -ResourceGroupName "myRG!"`

**Results of testing:** The invalid input was rejected by the parameter before execution reached the Azure command. The error returned was: `Cannot validate argument on parameter 'ResourceGroupName'. The argument "myRG!" does not match the "^[a-zA-Z0-9-_]+$" pattern.` The valid input passed validation and execution reached line 27.

## Task 4: Implement Structured Error Handling
**Error generated:** Missing Azure connection. The script was run without an authenticated Azure session.

**Error message received:** `Run Connect-AzAccount to login.`

**How the Catch block handled the failure:** Instead of the script failing with raw PowerShell error text, the Catch block caught the terminating error and returned a readable message stating the resource group could not be created, along with the underlying error. Adding `-ErrorAction Stop` was required because `New-AzResourceGroup` throws a non-terminating error by default, which Try/Catch would not have caught.

**What occurred in Finally:** The Finally block ran and returned "Script execution finished." This block runs whether the command succeeds or fails, so it confirms the script completed and exited cleanly.

## Task 5: Add Logging and Improve Readability
**Transcript file location:** `C:\powershell-advanced-mike\LM1\create-resourcegroup.log.txt`

**Example entry from the transcript:** `Error: Run Connect-AzAccount to login.`

**Readability improvement 1:** Renamed the variable from `$a` to `$ResourceGroupName` so the code states what the value actually holds instead of requiring the reader to trace it through the script.

**Readability improvement 2:** Added comments above each block explaining what it does, and added blank lines between the comment-based help sections so the header is easier to scan.
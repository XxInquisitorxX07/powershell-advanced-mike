# LM2 Lab

## Task 1: Identify and Correct Script Errors
**Original command:**
```powershell
Get-Process -Name explore
```
**Error message received:**
```
Get-Process: Cannot find a process with the name "explore". Verify the process name and call the cmdlet again.
```
**Cause of the error:** The process name was misspelled. Windows File Explorer runs as a process called "explorer," and it was typed as "explore." The `-Name` parameter looks for an exact match, so when nothing matches it returns an error rather than an empty result.
**Corrected command:**
```powershell
Get-Process -Name explorer
```

## Task 2: Add Debugging Output
**Example of verbose output:**
```
PS C:\powershell-advanced-mike\LM1> .\create-resourcegroup.ps1 -ResourceGroupName "TestRG2" -Verbose
Transcript started, output file is .\create-resourcegroup.log.txt
VERBOSE: Starting script to create resource group 'TestRG2'.
VERBOSE: Attempting to create resource group 'TestRG2' in 'centralus' location.
VERBOSE: 11:52:55 AM - Created resource group 'TestRG2' in location 'centralus'

ResourceGroupName : TestRG2
Location          : centralus
ProvisioningState : Succeeded

Resource group 'TestRG2' created successfully.
VERBOSE: Resource group creation completed without errors.
Script execution finished.
VERBOSE: Stopping transcript and exiting script.
```
**Example of debug output:** (trimmed — the full run produced several hundred lines)
```
PS C:\powershell-advanced-mike\LM1> .\create-resourcegroup.ps1 -ResourceGroupName "TestRG3" -Debug
DEBUG: DebugPreference is set to Continue
DEBUG: About to call New-AzResourceGroup with -ErrorAction Stop to ensure any errors are caught.
DEBUG: NewAzureResourceGroupCmdlet begin processing with ParameterSet '__AllParameterSets'.
DEBUG: [Common.Authentication]: Authenticating using Account: 'mike.hagel@mh4372.onmicrosoft.com'
DEBUG: ============================ HTTP REQUEST ============================
HTTP Method: PUT
Absolute Uri: https://management.azure.com/subscriptions/.../resourcegroups/TestRG3?api-version=2021-04-01
Body: { "location": "centralus" }
DEBUG: ============================ HTTP RESPONSE ============================
Status Code: Created
...
Resource group 'TestRG3' created successfully.
DEBUG: Reached the end of the script execution block.
```
**Observed differences:** With the verbose run, it gives a small amount of information about the script that tells us what it did and when it completed. With the debug run, it gave way more lines, including details from inside the Az module such as the authentication process and the actual HTTP requests sent to Azure. Running the script without either switch showed neither type of message, so both are turned off by default.

## Task 3: Create Your First Pester Test
**Test name:** Creates the resource group in Azure
**Expected result:** The script creates the resource group in Azure, and Get-AzResourceGroup returns a group whose name matches the one that was passed in.
**Actual result:**
```
PS C:\powershell-advanced-mike\LM2> Invoke-Pester .\create-resourcegroup.tests.ps1

Running tests from 1 files.

Confirm
Provided resource group already exists. Are you sure you want to update it?
[Y] Yes  [N] No  [S] Suspend  [?] Help (default is "Y"): y
[+] C:\powershell-advanced-mike\LM2\create-resourcegroup.tests.ps1 32.32s (1 test)
Tests completed in 32.32s
Tests Passed: 1, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0
```
**Observation:** The test passed, but because the resource group already existed from a previous run, Azure prompted for confirmation before continuing. The test sat waiting until I pressed Y, and the run took 32 seconds instead of the 2.7 seconds it took the first time. An automated test that waits for a human to answer a prompt cannot run unattended, which defeats part of the purpose of automated testing.
# PowerShell Advanced

## Project Purpose

This repository contains coursework for the PowerShell Advanced class. The main project is `New-TestResourceGroup`, an advanced PowerShell function that creates Azure resource groups and is being prepared for inclusion in a PowerShell module.

The function started as a basic script in LM1 and has been hardened and refactored in each module since.

## Repository Structure

- `create-resourcegroup/`: the function, its Pester tests, and its documentation.
- `lab-files/`: lab writeups for each learning module, plus `ResourceGroups.txt` for bulk testing.
- `output/`: transcript logs written by the function.

## The Function

`New-TestResourceGroup` creates Azure resource groups in the centralus region. A resource group can be named directly with `-ResourceGroupName`, or generated from a project ID with `-ProjectID` (for example, `1001` becomes `RG-1001`). Project IDs can be piped in or read from a file for bulk creation.

Each request returns a `PSCustomObject` with a status of `Created`, `Skipped`, or `Failed`. Existing resource groups are skipped instead of being updated. Errors are caught so one failure does not stop the run. A summary at the end shows the total, created, skipped, and error counts. The function also supports `-WhatIf`, `-Confirm`, and labeled `-Verbose` messages.

Full usage details are in `create-resourcegroup/README.md`.

## Running the Tests

```powershell
Invoke-Pester .\create-resourcegroup\create-resourcegroup.tests.ps1 -Output Detailed
```

The Azure cmdlets are mocked, so no real resources are created.

## Module History

| Module | What Was Added |
| --- | --- |
| LM1 | Basic script that creates a resource group |
| LM2 | Verbose and debug output, Pester testing |
| LM3 | Advanced function with validation, tags, pipeline support, structured output, `-WhatIf`, and transcript logging |
| LM4 | Parameter sets, bulk processing, labeled verbose messages, skip check, execution counters, run summary, and rewritten Pester tests |

## Lessons Learned

**LM2: Verbose and debug output.** Running Verbose and Debug helps ensure a script will work as intended without causing downtime in the future. Verbose shows only the messages I wrote, while Debug propagates into every command that gets called, including the Az module's HTTP requests.

**LM2: Tenant mismatch.** Signing in worked and I had Owner permissions on the subscription, but I was signing into the wrong directory. Azure reported it as a permissions error, which pointed me in the wrong direction at first.

**LM2: Automated testing and existing state.** When running the Pester segment it passed but waited for user input, since I ran it prior and it was waiting for authorization to replace the already created group. A test that waits for someone to press a key cannot run unattended, which defeats part of the purpose of automated testing.

**LM3: Pipeline processing.** Without a `process` block, piping multiple values into a function only uses the last one, with no error message to indicate the rest were dropped.

**LM3: Switch propagation.** `-WhatIf` and `-Confirm` propagate into every command called inside a function, not just the code wrapped in `ShouldProcess`. The two switches are independent, so opting a command out of one does not opt it out of the other.

**LM3: Relative paths.** `Start-Transcript` resolves relative paths against the working directory at the time of the call, not the script's location. Using `$PSScriptRoot` fixes this permanently.

**LM4: Parameter sets and the pipeline.** Only one parameter set should accept pipeline input. Setting `DefaultParameterSetName` tells PowerShell which set to use when a value is piped in.

**LM4: Counters belong in `begin`.** The `begin` block runs once, while `process` runs for every item. If a counter is created in `process`, it resets for every item.

**LM4: Output stream pollution.** `Start-Transcript` and `Stop-Transcript` put their messages in the output stream, so saved results held 7 items instead of 5. Sending them to `Out-Null` keeps the output clean.

**LM4: Skipping existing resources.** Checking with `Get-AzResourceGroup` before creating keeps a bulk run from stalling on an "update existing group?" prompt, and it also fixes the unattended-testing problem from LM2.

**LM4: Tests need maintenance.** The old Pester test still pointed at the `LM1` folder after the LM3 reorganization, so it had been broken without anyone noticing. Mocking the Azure cmdlets makes the tests fast and repeatable, with no real resources created.
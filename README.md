# PowerShell Advanced

## Project Purpose

This repository contains coursework for the PowerShell Advanced class. The main project is `New-TestResourceGroup`, an advanced PowerShell function that creates Azure resource groups. In LM5 it was packaged into the **NWTC.ResourceGroups** PowerShell module.

The function started as a basic script in LM1 and has been hardened and refactored in each module since.

## Repository Structure

- `NWTC.ResourceGroups/`: the PowerShell module (current version of the function).
  - `Public/`: exported functions (`New-TestResourceGroup`).
  - `Private/`: internal helpers (`Write-ModuleLog`), loaded but not exported.
  - `Docs/`: module README with installation and usage instructions.
  - `Logs/`: per-run log files (not tracked in Git).
  - `Tests/`: reserved for module Pester tests.
- `create-resourcegroup/`: the standalone LM4 version of the function, its Pester tests, and the function README.
- `lab-files/`: lab writeups for each learning module, plus `ResourceGroups.txt` for bulk testing.
- `output/`: transcript logs from the standalone LM4 version.

## The Module

`NWTC.ResourceGroups` (version 1.0.0) packages `New-TestResourceGroup` with a manifest, a loader that separates public and private functions, and its own logging.

```powershell
Connect-AzAccount -TenantId "mh4372.onmicrosoft.com"
Import-Module .\NWTC.ResourceGroups\NWTC.ResourceGroups.psd1
Get-Command -Module NWTC.ResourceGroups
```

Installation, usage, and version details are in `NWTC.ResourceGroups/Docs/README.md`.

## The Function

`New-TestResourceGroup` creates Azure resource groups in the centralus region. A resource group can be named directly with `-ResourceGroupName`, or generated from a project ID with `-ProjectID` (for example, `1001` becomes `RG-1001`). Both parameters accept comma-separated lists, and project IDs can also be piped in or read from a file for bulk creation.

Each request returns a `PSCustomObject` with a status of `Created`, `Skipped`, or `Failed`. Existing resource groups are skipped instead of being updated. Errors are caught so one failure does not stop the run. A summary at the end shows the total, created, skipped, and error counts. Every run is logged to a timestamped file. The function also supports `-WhatIf`, `-Confirm`, and labeled `-Verbose` messages.

Full usage details are in `create-resourcegroup/README.md`.

## Running the Tests

```powershell
Invoke-Pester .\create-resourcegroup\create-resourcegroup.tests.ps1 -Output Detailed
```

The Azure cmdlets are mocked, so no real resources are created. These tests cover the standalone LM4 version; the module version was tested manually in LM5.

## Module History

| Module | What Was Added |
| --- | --- |
| LM1 | Basic script that creates a resource group |
| LM2 | Verbose and debug output, Pester testing |
| LM3 | Advanced function with validation, tags, pipeline support, structured output, `-WhatIf`, and transcript logging |
| LM4 | Parameter sets, bulk processing, labeled verbose messages, skip check, execution counters, run summary, and rewritten Pester tests |
| LM5 | Packaged as the NWTC.ResourceGroups module: manifest (v1.0.0), Public/Private structure, controlled exports, private `Write-ModuleLog` helper replacing the transcript, array input for both parameters, and module documentation |

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

**LM5: `$PSScriptRoot` depends on where the code lives.** Inside a function, `$PSScriptRoot` is the folder of the file the function is defined in. After moving the function into `Public`, the log path pointed to the wrong folder until I went up one level with `Split-Path -Parent`.

**LM5: The manifest needs `RootModule`.** A manifest without `RootModule` imports with a version number but no commands. The `.psm1` holds the code; the `.psd1` only describes it and points to it.

**LM5: Exports are opt-in once you start controlling them.** A `.psm1` exports every function by default. `Export-ModuleMember` limits exports to the public functions, which is what keeps private helpers like `Write-ModuleLog` hidden.

**LM5: Leftover copies hide problems.** A dot-sourced copy of a function stays in the session and can make a module look like it works. Removing the module and the test function before re-testing made sure results came from the module itself.

**LM5: Test the packaged version.** Testing the module found that `-ProjectID 1017, 1018` failed because the parameter was a single `[string]`. Changing it to `[string[]]` with a loop in `process` fixed it without changing pipeline behavior.

**LM5: Git doesn't track empty folders.** The new module folders needed `.gitkeep` placeholder files to show up on GitHub.
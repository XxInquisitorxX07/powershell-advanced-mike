# PowerShell Advanced
## Project Purpose
This repository contains coursework for the PowerShell Advanced class. The main project is `New-TestResourceGroup`, an advanced PowerShell function that creates Azure resource groups with parameter validation, tagging, pipeline support, structured output, and WhatIf support.

The function started as a basic script in LM1 and has been hardened and refactored in each module since.
## Repository Structure
- `create-resourcegroup/` — The function, its Pester tests, and its documentation.
- `lab-files/` — Lab writeups for each learning module.
- `output/` — Transcript logs written by the function.
## The Function
`New-TestResourceGroup` creates an Azure resource group in the centralus region. It takes a mandatory resource group name that is validated with `ValidatePattern` and can be piped in, plus an optional hashtable of tags that defaults to Department and Environment values. It returns a `PSCustomObject` with the resource group name, location, status, tags, and timestamp rather than plain text, so the results can be filtered, sorted, or exported. Because it uses `SupportsShouldProcess`, it also supports `-WhatIf` and `-Confirm`.

Full usage details are in `create-resourcegroup/README.md`.
## Lessons Learned
**LM2 — Verbose and debug output.** Running Verbose and Debug helps ensure a script will work as intended without causing downtime in the future. Verbose shows only the messages I wrote, while Debug propagates into every command that gets called, including the Az module's HTTP requests.

**LM2 — Tenant mismatch.** Signing in worked and I had Owner permissions on the subscription, but I was signing into the wrong directory. Azure reported it as a permissions error, which pointed me in the wrong direction at first.

**LM2 — Automated testing and existing state.** When running the Pester segment it passed but waited for user input, since I ran it prior and it was waiting for authorization to replace the already created group. A test that waits for someone to press a key cannot run unattended, which defeats part of the purpose of automated testing.

**LM3 — Pipeline processing.** Without a `process` block, piping multiple values into a function only uses the last one, with no error message to indicate the rest were dropped.

**LM3 — Switch propagation.** `-WhatIf` and `-Confirm` propagate into every command called inside a function, not just the code wrapped in `ShouldProcess`. The two switches are independent, so opting a command out of one does not opt it out of the other.

**LM3 — Relative paths.** `Start-Transcript` resolves relative paths against the working directory at the time of the call, not the script's location. Using `$PSScriptRoot` fixes this permanently.
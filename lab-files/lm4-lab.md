# LM4 Lab Journal

## Task 1: Review the Existing Function

### Strengths

1. The function already has input validation, so invalid input can be caught before it ever tries to create anything in Azure. This helps prevent unnecessary errors and makes the function more reliable.
2. `-WhatIf` support lets me preview what the function is going to do before it actually makes changes. This is especially useful when working with multiple resource groups because I can make sure the input is correct first.
3. The function supports pipeline input and returns structured objects instead of only plain text. This makes it easier to process multiple resource groups and use the results with other PowerShell commands.

### Improvements

1. The function currently requires the full resource group name every time, so adding another way to generate names from a project ID would make it easier to use.
2. There is not much feedback while the function is running, so adding progress or status messages would make it easier to tell what step it is currently working on.
3. The function does not give a summary after a bulk run showing how many resource groups were created, skipped, or failed. Adding a final summary would make the results easier to understand without having to look through every individual result.

## Task 2: Add Parameter Sets

I added two parameter sets, `ResourceGroupName` and `ProjectID`, so the function can accept either a full resource group name or a project number. When `ProjectID` is used, the function automatically builds the resource group name using the `RG-` prefix, so `ProjectID 1001` becomes `RG-1001`.

The function checks `$PSCmdlet.ParameterSetName` to determine which parameter set was used and which resource group name it should work with. Only `ProjectID` accepts pipeline input, and the default parameter set is `ProjectID`, so piping in a value like `1001` automatically uses that option.

I tested both parameter sets with `-WhatIf` and then created resource groups successfully with each one. I also tested using `ProjectID` and `ResourceGroupName` together, and PowerShell correctly rejected the command because they belong to different parameter sets.

This makes the function easier to use while still preventing conflicting input.

## Task 3: Implement Begin, Process, and End Blocks

The `begin` block runs one time at the start of the function, the `process` block runs once for each item that comes through the pipeline, and the `end` block runs one time after everything is finished. This keeps the setup, individual work, and final summary separated.

In the `begin` block, I set the start time, request counter, and location. These need to be set once before the pipeline starts, because if the counter were created inside `process`, it would reset every time a new resource group was handled.

I tested it by piping in three `ProjectID` values, and the function processed all three resource groups separately. The final run created `RG-1002`, `RG-1003`, and `RG-1004`, but only produced one run summary showing three requests processed and the total elapsed time.

The `begin`, `process`, and `end` blocks were already part of the function from LM3, but this task helped show why they matter. The counter and timing only work correctly because `begin` runs once while `process` handles each resource group individually.

## Task 4: Improve User Feedback

I added verbose messages to make it easier to see what the function is doing without always showing extra information. The `[START]` message is in the `begin` block, `[VALIDATION]` is in the `process` block after the resource group name is determined, `[ATTEMPT]` runs before the Azure creation command, `[SUCCESS]` runs after the resource group is created, and `[COMPLETE]` is in the `end` block after all requests are finished.

The validation message has to be inside `process` because `ValidatePattern` checks the parameter before the function body even starts. If the value does not pass validation, PowerShell stops it before any of my verbose messages inside the function would run.

I used `Write-Verbose` instead of `Write-Host` because the extra information stays hidden during a normal run and only appears when the admin uses `-Verbose`. This keeps the normal output clean but still gives more detail when troubleshooting.

I tested the function normally, with `-WhatIf -Verbose`, and with a real creation using `-Verbose`. The normal run did not show the verbose messages, the `-WhatIf` test showed `[START]`, `[VALIDATION]`, `[SKIPPED]`, and `[COMPLETE]`, and the real run also showed the `[ATTEMPT]` and `[SUCCESS]` messages.

I also learned that `-Verbose` gets passed along to what the function calls. `New-AzResourceGroup` displayed its own verbose message about creating the resource group, and `ShouldProcess` displayed a message about the operation it was approving.

## Task 5: Process Multiple Resource Groups

I created `ResourceGroups.txt` with five project IDs, one per line. I used new `ProjectID` values so `New-AzResourceGroup` would actually create new resource groups instead of running against ones that already existed and possibly prompting or updating them.

Commands used:

```powershell
Set-Content -Path .\lab-files\ResourceGroups.txt -Value "1006","1007","1008","1009","1010"
Get-Content .\lab-files\ResourceGroups.txt | New-TestResourceGroup -WhatIf
$results = Get-Content .\lab-files\ResourceGroups.txt | New-TestResourceGroup
$results.Count
$results | Group-Object Status | Select-Object Name, Count
$results | Where-Object { $_ -is [string] }
```

### Results

- Objects processed: 5
- Successfully created: 5 (`RG-1006` through `RG-1010`)
- Warnings generated: None

### Issue Found

`$results.Count` showed 7 instead of 5. The two transcript messages were also being captured in `$results` as strings, which added the extra 2 items. That could cause problems for anything using the results later, like `Group-Object` or `Export-Csv`, because the output would contain both resource group objects and unrelated text. I will fix this in Task 6 by sending the transcript messages to `Out-Null`.

## Task 6: Add Execution Statistics

I added four counters to track the total requests, created resource groups, skipped resource groups, and errors. The counters are set to zero in the `begin` block, increased in the `process` block depending on what happens with each request, and then displayed in the `end` block as the final run summary.

Before trying to create anything, the function now uses `Get-AzResourceGroup` to check whether the resource group already exists. This check happens before `ShouldProcess` so an existing group can be skipped cleanly instead of asking for confirmation or trying to update something that is already there.

I also fixed the Task 5 issue where the transcript start and stop messages were getting mixed into the function output. Adding `| Out-Null` to the transcript commands keeps those strings out of the pipeline, so the results only contain the resource group objects.

I tested three different situations. The first test processed five existing resource groups and showed 5 skipped, 0 created, and 0 errors, and `$results.Count` returned 5, which confirmed the transcript fix worked. The second test used one existing group and one new group, and the summary correctly showed 1 skipped and 1 created. The third test used an invalid tag name, and the function caught the Azure error and showed 1 error with nothing created or skipped.

The main thing I learned is that every request should end in only one result: created, skipped, or failed. Because each request only increases one of those counters, the created, skipped, and error totals should always add back up to the total requests processed.

## Task 7: Prepare for Module Development

I updated both README files so they match the current LM4 version of the function instead of describing how it worked in earlier modules. The function README now explains the parameter sets, bulk input, verbose messages, skip behavior, output, run summary, and testing, while the main repository README shows how the project has changed through each module. Good documentation becomes more important when a function is moved into a module because other admins need to understand how to use it without reading through all of the code.

I also kept the comment-based help updated as changes were made, so `Get-Help New-TestResourceGroup` gives information that matches how the function actually works. This helps prevent someone from following old examples or using parameters that have changed.

The Pester tests also needed to be rewritten because the old test still pointed to the `LM1` folder and had been broken since the repository was reorganized in LM3. The new tests dot-source the current function and mock the Azure commands so they can test the function without creating real Azure resources. All 10 tests passed.

One thing I learned was that the function has to be dot-sourced inside `BeforeAll` so it is loaded before the tests run. I also learned to check which tab I am editing before pasting changes because it is easy to overwrite the wrong file. Git makes it possible to recover with `git restore`, but only back to the last commit, which is another reason to commit after each task.
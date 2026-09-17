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
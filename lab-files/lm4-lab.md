# LM4 Lab Journal

## Task 1: Review the Existing Function

### Strengths

1.The function already has input validation, so invalid input can be caught before it ever tries to create anything in Azure. This helps prevent unnecessary errors and makes the function more reliable.
2.WhatIf support lets me preview what the function is going to do before it actually makes changes. This is especially useful when working with multiple resource groups because I can make sure the input is correct first.
3.The function supports pipeline input and returns structured objects instead of only plain text. This makes it easier to process multiple resource groups and use the results with other PowerShell commands.

### Improvements

1.The function currently requires the full resource group name every time, so adding another way to generate names from a project ID would make it easier to use.
2.There is not much feedback while the function is running, so adding progress or status messages would make it easier to tell what step it is currently working on.
3.The function does not give a summary after a bulk run showing how many resource groups were created, skipped, or failed. Adding a final summary would make the results easier to understand without having to look through every individual result.
function New-TestResourceGroup {
    <# 
    .SYNOPSIS
        Creates a new Azure Resource Group
    .DESCRIPTION
        This function creates a new Azure Resource Group in the 'centralus' location.
        The name can be supplied directly with -ResourceGroupName, or generated
        automatically from a project ID with -ProjectID (naming convention: RG-<ProjectID>).
        Both parameters accept one value or a comma-separated list, and -ProjectID also
        accepts pipeline input for bulk creation. Resource groups that already exist
        are skipped. A summary of total, created, skipped, and failed requests is displayed
        when the run finishes. Use -Verbose to see step-by-step progress messages.
        Each run writes a timestamped log file to the module's Logs folder.
    .PARAMETER ResourceGroupName
        One or more full Resource Group names to create.
        Used in the 'ResourceGroupName' parameter set.
    .PARAMETER ProjectID
        One or more numeric project identifiers. Each name is generated as RG-<ProjectID>.
        Used in the 'ProjectID' parameter set. Accepts input from the pipeline.
    .PARAMETER Tags
        Optional hashtable of tags to apply to the Resource Group.
        Defaults to @{Department="IT"; Environment="Test"}.
    .EXAMPLE
        PS C:\> New-TestResourceGroup -ResourceGroupName Dev1
        Creates a Resource Group named 'Dev1'.
    .EXAMPLE
        PS C:\> New-TestResourceGroup -ProjectID 1001
        Creates a Resource Group named 'RG-1001'.
    .EXAMPLE
        PS C:\> New-TestResourceGroup -ProjectID 1017, 1018
        Creates 'RG-1017' and 'RG-1018' in one run.
    .EXAMPLE
        PS C:\> Get-Content .\ResourceGroups.txt | New-TestResourceGroup
        Creates a Resource Group for each project ID in the file, skipping any that already exist.
    .EXAMPLE
        PS C:\> New-TestResourceGroup -ProjectID 1005 -Verbose
        Creates 'RG-1005' and shows progress messages for each step.
    .EXAMPLE
        PS C:\> New-TestResourceGroup -ProjectID 1001 -Tags @{Department="Dev";Environment="Development"}
        Creates 'RG-1001' with custom tags.
    .EXAMPLE
        PS C:\> "1001" | New-TestResourceGroup -WhatIf
        Shows what would happen without creating the Resource Group. The run is still logged.
    .OUTPUTS
        PSCustomObject with ResourceGroupName, Location, Status, Tags, and Timestamp properties.
        Status is one of: Created, Skipped, Failed.
    .NOTES
        Author: Mike Hagel 
        Date: 2026 Sep 06 - Added pipeline input, structured output, and ShouldProcess support
        Date: 2026 Sep 17 - Added ResourceGroupName and ProjectID parameter sets
        Date: 2026 Sep 17 - Added Begin/Process/End initialization, startup message, and run summary
        Date: 2026 Sep 17 - Added verbose messages for start, validation, creation attempt, and completion
        Date: 2026 Sep 17 - Added execution counters, skip check for existing groups, and removed transcript text from output
        Date: 2026 Sep 24 - Moved into NWTC.ResourceGroups module; replaced Start/Stop-Transcript with private Write-ModuleLog helper
        Date: 2026 Sep 24 - ProjectID and ResourceGroupName now accept arrays (comma-separated lists)
        Course: PowerShell Advanced
    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        DefaultParameterSetName = 'ProjectID'
    )]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName = 'ResourceGroupName'
        )]
        [ValidatePattern('^[a-zA-Z0-9_-]+$')]
        [string[]]$ResourceGroupName,

        [Parameter(
            Mandatory,
            ParameterSetName = 'ProjectID',
            ValueFromPipeline = $true
        )]
        [ValidatePattern('^\d+$')]
        [string[]]$ProjectID,

        # No ParameterSetName = available in both parameter sets
        [hashtable]$Tags = @{
            Department  = "IT"
            Environment = "Test"
        }
    )
    begin {
        # Build the log file path.
        # $PSScriptRoot here is the Public folder (where this file lives), NOT the module root,
        # so go up one level to reach the module's Logs folder.
        # One log file per run, named with the run's start time.
        $moduleRoot = Split-Path -Path $PSScriptRoot -Parent
        $logFile    = Join-Path $moduleRoot "Logs\New-TestResourceGroup-Log-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

        # Initialize variables once, before any pipeline objects arrive
        $startTime    = Get-Date
        $location     = 'centralus'
        $totalCount   = 0
        $createdCount = 0
        $skippedCount = 0
        $errorCount   = 0

        # Startup message
        Write-Host "Starting New-TestResourceGroup at $($startTime.ToString('g')) (location: $location)"
        Write-ModuleLog -Message "Starting the creation of Resource Group... (parameter set: $($PSCmdlet.ParameterSetName))" -Level INFO -LogFile $logFile
        Write-Verbose "[START] Function started. Parameter set: '$($PSCmdlet.ParameterSetName)'. Logging to '$logFile'."
        Write-Debug "DebugPreference is set to $DebugPreference"
    }
    process {
        # Runs once for EACH pipeline object.
        # Each parameter can now hold several values (-ProjectID 1017, 1018),
        # so loop over whichever one was used.
        if ($PSCmdlet.ParameterSetName -eq 'ProjectID') {
            $inputValues = $ProjectID
        }
        else {
            $inputValues = $ResourceGroupName
        }

        foreach ($value in $inputValues) {
            $totalCount++

            # Work out the final name based on which parameter set was used
            if ($PSCmdlet.ParameterSetName -eq 'ProjectID') {
                $rgName = "RG-$value"
                # ValidatePattern already checked every value before this block ran
                Write-ModuleLog -Message "Creating Resource Group based on ProjectID: $value" -Level INFO -LogFile $logFile
                Write-Verbose "[VALIDATION] ProjectID '$value' passed validation. Generated name: '$rgName'."
            }
            else {
                $rgName = $value
                Write-ModuleLog -Message "Creating Resource Group based on ResourceGroupName: $rgName" -Level INFO -LogFile $logFile
                Write-Verbose "[VALIDATION] ResourceGroupName '$rgName' passed validation."
            }

            # Build the result object, defaulting to a not-created state
            $result = [PSCustomObject]@{
                ResourceGroupName = $rgName
                Location          = $location
                Status            = 'Not Created'
                Tags              = $Tags
                Timestamp         = Get-Date
            }

            # Skip resource groups that already exist
            # Get-AzResourceGroup is read-only, so it runs even during -WhatIf
            $existing = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
            if ($existing) {
                $result.Status = 'Skipped'
                $skippedCount++
                Write-ModuleLog -Message "Resource Group '$rgName' already exists. Skipping." -Level WARN -LogFile $logFile
                Write-Warning "Resource group '$rgName' already exists. Skipping."
            }
            # Only create the resource group if ShouldProcess approves
            elseif ($PSCmdlet.ShouldProcess(
                    "Resource Group '$rgName'",
                    "Create"
                )) {
                try {
                    # Attempt to create the resource group
                    Write-ModuleLog -Message "Creating Resource Group '$rgName' in '$location'" -Level INFO -LogFile $logFile
                    Write-Verbose "[ATTEMPT] Creating resource group '$rgName' in '$location' with tags: $($Tags.Keys -join ', ')."
                    Write-Debug "About to call New-AzResourceGroup with -ErrorAction Stop to ensure any errors are caught."
                    New-AzResourceGroup `
                        -Name $rgName `
                        -Location $location `
                        -Tag $Tags `
                        -ErrorAction Stop | Out-Null
                    $result.Status = 'Created'
                    $createdCount++
                    Write-ModuleLog -Message "Resource Group '$rgName' created successfully." -Level INFO -LogFile $logFile
                    Write-Verbose "[SUCCESS] Resource group '$rgName' created successfully."
                }
                catch {
                    # Handle any errors that occur during resource group creation
                    $result.Status = 'Failed'
                    $errorCount++
                    Write-ModuleLog -Message "Failed to create Resource Group '$rgName'. Error: $($_.Exception.Message)" -Level ERROR -LogFile $logFile
                    Write-Warning "Failed to create resource group '$rgName'. Error: $($_.Exception.Message)"
                }
            }
            else {
                # -WhatIf was used or Confirm was declined
                $result.Status = 'Skipped'
                $skippedCount++
                Write-ModuleLog -Message "Creation of '$rgName' was not performed (WhatIf or Confirm declined)." -Level INFO -LogFile $logFile
                Write-Verbose "[SKIPPED] Creation of '$rgName' was not performed (WhatIf or Confirm declined)."
            }

            # Emit the structured result for this value
            $result
        }
    }
    end {
        # Runs once, after ALL pipeline objects are processed
        $duration = (Get-Date) - $startTime
        Write-Host ""
        Write-Host "===== Run Summary ====="
        Write-Host "Total requests processed : $totalCount"
        Write-Host "Created successfully     : $createdCount"
        Write-Host "Skipped                  : $skippedCount"
        Write-Host "Errors                   : $errorCount"
        Write-Host "Elapsed time             : $([math]::Round($duration.TotalSeconds, 1)) seconds"

        Write-ModuleLog -Message "Finished processing the creation of Resource Group. Total: $totalCount, Created: $createdCount, Skipped: $skippedCount, Errors: $errorCount" -Level INFO -LogFile $logFile
        Write-Verbose "[COMPLETE] Processed $totalCount request(s). Log saved to '$logFile'."
        Write-Debug "Reached the end of the function execution block."
    }
}
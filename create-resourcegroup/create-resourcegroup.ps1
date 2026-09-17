function New-TestResourceGroup {
    <# 
    .SYNOPSIS
        Creates a new Azure Resource Group
    .DESCRIPTION
        This function creates a new Azure Resource Group in the 'centralus' location.
        The name can be supplied directly with -ResourceGroupName, or generated
        automatically from a project ID with -ProjectID (naming convention: RG-<ProjectID>).
        Supports bulk creation through pipeline input and displays a summary when finished.
        Use -Verbose to see step-by-step progress messages.
    .PARAMETER ResourceGroupName
        The full name of the Resource Group to create.
        Used in the 'ResourceGroupName' parameter set.
    .PARAMETER ProjectID
        A numeric project identifier. The Resource Group name is generated as RG-<ProjectID>.
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
        PS C:\> "1002","1003","1004" | New-TestResourceGroup
        Creates three Resource Groups (RG-1002, RG-1003, RG-1004) using pipeline input.
    .EXAMPLE
        PS C:\> New-TestResourceGroup -ProjectID 1005 -Verbose
        Creates 'RG-1005' and shows progress messages for each step.
    .EXAMPLE
        PS C:\> New-TestResourceGroup -ProjectID 1001 -Tags @{Department="Dev";Environment="Development"}
        Creates 'RG-1001' with custom tags.
    .EXAMPLE
        PS C:\> "1001" | New-TestResourceGroup -WhatIf
        Shows what would happen without creating the Resource Group.
    .OUTPUTS
        PSCustomObject with ResourceGroupName, Location, Status, Tags, and Timestamp properties.
    .NOTES
        Author: Mike Hagel 
        Date: 2026 Sep 06 - Added pipeline input, structured output, and ShouldProcess support
        Date: 2026 Sep 17 - Added ResourceGroupName and ProjectID parameter sets
        Date: 2026 Sep 17 - Added Begin/Process/End initialization, startup message, and run summary
        Date: 2026 Sep 17 - Added verbose messages for start, validation, creation attempt, and completion
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
        [string]$ResourceGroupName,

        [Parameter(
            Mandatory,
            ParameterSetName = 'ProjectID',
            ValueFromPipeline = $true
        )]
        [ValidatePattern('^\d+$')]
        [string]$ProjectID,

        # No ParameterSetName = available in both parameter sets
        [hashtable]$Tags = @{
            Department  = "IT"
            Environment = "Test"
        }
    )
    begin {
        # Start logging script activity to a log file
        # -WhatIf:$false and -Confirm:$false opt logging out of ShouldProcess so that
        # only the resource group creation is governed by -WhatIf and -Confirm
        Start-Transcript -Path (Join-Path $PSScriptRoot "..\output\create-resourcegroup.log.txt") -WhatIf:$false -Confirm:$false

        # Initialize variables once, before any pipeline objects arrive
        $startTime      = Get-Date
        $processedCount = 0
        $location       = 'centralus'

        # Startup message
        Write-Host "Starting New-TestResourceGroup at $($startTime.ToString('g')) (location: $location)"
        Write-Verbose "[START] Function started. Parameter set: '$($PSCmdlet.ParameterSetName)'."
        Write-Debug "DebugPreference is set to $DebugPreference"
    }
    process {
        # Runs once for EACH pipeline object
        $processedCount++

        # Work out the final name based on which parameter set was used
        if ($PSCmdlet.ParameterSetName -eq 'ProjectID') {
            $rgName = "RG-$ProjectID"
            # ValidatePattern already ran before this block; reaching here means input passed
            Write-Verbose "[VALIDATION] ProjectID '$ProjectID' passed validation. Generated name: '$rgName'."
        }
        else {
            $rgName = $ResourceGroupName
            Write-Verbose "[VALIDATION] ResourceGroupName '$rgName' passed validation."
        }

        # Build the result object, defaulting to a failed state
        $result = [PSCustomObject]@{
            ResourceGroupName = $rgName
            Location          = $location
            Status            = 'Not Created'
            Tags              = $Tags
            Timestamp         = Get-Date
        }

        # Only create the resource group if ShouldProcess approves
        if ($PSCmdlet.ShouldProcess(
                "Resource Group '$rgName'",
                "Create"
            )) {
            try {
                # Attempt to create the resource group
                Write-Verbose "[ATTEMPT] Creating resource group '$rgName' in '$location' with tags: $($Tags.Keys -join ', ')."
                Write-Debug "About to call New-AzResourceGroup with -ErrorAction Stop to ensure any errors are caught."
                New-AzResourceGroup `
                    -Name $rgName `
                    -Location $location `
                    -Tag $Tags `
                    -ErrorAction Stop | Out-Null
                $result.Status = 'Created'
                Write-Verbose "[SUCCESS] Resource group '$rgName' created successfully."
            }
            catch {
                # Handle any errors that occur during resource group creation
                Write-Warning "Failed to create resource group '$rgName'. Error: $($_.Exception.Message)"
            }
        }
        else {
            Write-Verbose "[SKIPPED] Creation of '$rgName' was not performed (WhatIf or Confirm declined)."
        }

        # Emit the structured result for this pipeline object
        $result
    }
    end {
        # Runs once, after ALL pipeline objects are processed
        $duration = (Get-Date) - $startTime
        Write-Host ""
        Write-Host "===== Run Summary ====="
        Write-Host "Requests processed : $processedCount"
        Write-Host "Elapsed time       : $([math]::Round($duration.TotalSeconds, 1)) seconds"

        Write-Verbose "[COMPLETE] Processed $processedCount request(s). Stopping transcript."
        Write-Debug "Reached the end of the function execution block."
        Stop-Transcript -WhatIf:$false -Confirm:$false
    }
}
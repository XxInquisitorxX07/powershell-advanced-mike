function New-TestResourceGroup {
    <# 
    .SYNOPSIS
        Creates a new Azure Resource Group
    .DESCRIPTION
        This function creates a new Azure Resource Group with the specified name and location.
    .PARAMETER ResourceGroupName
        The name of the Resource Group to create.
        Accepts input from the pipeline.
    .PARAMETER Tags
        Optional hashtable of tags to apply to the Resource Group.
        Defaults to @{Department="IT"; Environment="Test"}.
    .EXAMPLE
        PS C:\> New-TestResourceGroup -ResourceGroupName MyResourceGroup
        This will create a new Resource Group named 'MyResourceGroup' in the 'centralus' location.
    .EXAMPLE
        PS C:\> New-TestResourceGroup -ResourceGroupName DevTest -Tags @{Department="Dev";Environment="Development"}
        Creates a Resource Group with custom tags.
    .EXAMPLE
        PS C:\> "DevTest" | New-TestResourceGroup
        Creates a Resource Group named 'DevTest' using pipeline input.
    .EXAMPLE
        PS C:\> "DevTest" | New-TestResourceGroup -WhatIf
        Shows what would happen without creating the Resource Group.
    .OUTPUTS
        PSCustomObject with ResourceGroupName, Location, Status, Tags, and Timestamp properties.
    .NOTES
        Author: Mike Hagel 
        Date: 2026 Sep 06 - Added pipeline input, structured output, and ShouldProcess support
        Course: PowerShell Advanced
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline = $true
        )]
        [ValidatePattern('^[a-zA-Z0-9_-]+$')]
        [string]$ResourceGroupName,
        [hashtable]$Tags = @{
            Department  = "IT"
            Environment = "Test"
        }
    )
    begin {
        # Start logging script activity to a log file
        # -WhatIf:$false and -Confirm:$false opt logging out of ShouldProcess so that
        # only the resource group creation is governed by -WhatIf and -Confirm
        Start-Transcript -Path ".\create-resourcegroup.log.txt" -WhatIf:$false -Confirm:$false
        Write-Verbose "Starting resource group creation process."
        Write-Debug "DebugPreference is set to $DebugPreference"
    }
    process {
        # Build the result object, defaulting to a failed state
        $result = [PSCustomObject]@{
            ResourceGroupName = $ResourceGroupName
            Location          = 'centralus'
            Status            = 'Not Created'
            Tags              = $Tags
            Timestamp         = Get-Date
        }

        # Only create the resource group if ShouldProcess approves
        if ($PSCmdlet.ShouldProcess(
                "Resource Group '$ResourceGroupName'",
                "Create"
            )) {
            try {
                # Attempt to create the resource group
                Write-Verbose "Attempting to create resource group '$ResourceGroupName' in 'centralus' location."
                Write-Debug "About to call New-AzResourceGroup with -ErrorAction Stop to ensure any errors are caught."
                Write-Verbose "Applying tags: $($Tags.Keys -join ', ')"
                New-AzResourceGroup `
                    -Name $ResourceGroupName `
                    -Location centralus `
                    -Tag $Tags `
                    -ErrorAction Stop | Out-Null
                $result.Status = 'Created'
                Write-Verbose "Resource group creation completed without errors."
            }
            catch {
                # Handle any errors that occur during resource group creation
                Write-Warning "Failed to create resource group '$ResourceGroupName'. Error: $($_.Exception.Message)"
            }
        }

        # Emit the structured result for this pipeline object
        $result
    }
    end {
        # Always stop the transcript when pipeline processing is finished
        Write-Verbose "Stopping transcript and exiting function."
        Write-Debug "Reached the end of the function execution block."
        Stop-Transcript -WhatIf:$false -Confirm:$false
    }
}
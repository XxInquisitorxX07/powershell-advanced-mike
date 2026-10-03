function Get-ResourceGroupSummary {
    <#
    .SYNOPSIS
        Returns a summary of Azure resource groups: name, location, and tags.

    .DESCRIPTION
        Get-ResourceGroupSummary reads resource groups from the current Azure
        subscription and returns one object per group with its name, location,
        and tags. Tags are flattened to a "Key=Value; Key=Value" string so they
        read cleanly in tables and reports. Groups with no tags show "None".

        With no -Name, every resource group in the subscription is returned.
        Names can be passed by parameter or through the pipeline. A name that
        is not found produces a warning and the function moves on to the next.

        This function is read-only. It never creates, changes, or deletes anything.

    .PARAMETER Name
        One or more resource group names to look up. Accepts pipeline input by
        value (strings) and by property name (ResourceGroupName), so output from
        New-TestResourceGroup or Get-AzResourceGroup can be piped straight in.

    .EXAMPLE
        Get-ResourceGroupSummary

        Returns a summary of every resource group in the subscription.

    .EXAMPLE
        Get-ResourceGroupSummary -Name 'RG-1001', 'Dev1'

        Returns a summary of two specific resource groups.

    .EXAMPLE
        'RG-1001', 'RG-1002' | Get-ResourceGroupSummary

        Looks up resource groups passed through the pipeline.

    .EXAMPLE
        Get-ResourceGroupSummary | Where-Object Tags -ne 'None' | Format-Table

        Shows only the resource groups that carry tags.

    .OUTPUTS
        PSCustomObject with ResourceGroupName, Location, and Tags properties.

    .NOTES
        Module:  NWTC.ResourceGroups
        Version: 1.1.0
        Author:  Mike Hagel
        Requires an active Azure session:
        Connect-AzAccount -TenantId "mh4372.onmicrosoft.com"
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position = 0,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('ResourceGroupName')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name
    )

    begin {
        Write-Verbose "[BEGIN] Get-ResourceGroupSummary started"
        $returned = 0
        $notFound = 0
    }

    process {
        if ($PSBoundParameters.ContainsKey('Name')) {
            $groups = foreach ($rgName in $Name) {
                Write-Verbose "[LOOKUP] $rgName"
                try {
                    Get-AzResourceGroup -Name $rgName -ErrorAction Stop
                }
                catch {
                    $notFound++
                    Write-Warning "[NOT FOUND] Resource group '$rgName' could not be read: $($_.Exception.Message)"
                }
            }
        }
        else {
            Write-Verbose "[LOOKUP] No name given - reading all resource groups in the subscription"
            $groups = Get-AzResourceGroup
        }

        foreach ($group in $groups) {
            if ($group.Tags -and $group.Tags.Count -gt 0) {
                $tagText = ($group.Tags.GetEnumerator() |
                    Sort-Object -Property Key |
                    ForEach-Object { '{0}={1}' -f $_.Key, $_.Value }) -join '; '
            }
            else {
                $tagText = 'None'
            }

            $returned++
            [PSCustomObject]@{
                ResourceGroupName = $group.ResourceGroupName
                Location          = $group.Location
                Tags              = $tagText
            }
        }
    }

    end {
        Write-Verbose "[END] Returned: $returned  Not found: $notFound"
    }
}
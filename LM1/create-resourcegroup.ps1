<# 
.SYNOPSIS
    Creates a new Azure Resource Group

.DESCRIPTION
    This script creates a new Azure Resource Group with the specified name and location.

.PARAMETER ResourceGroupName
    The name of the Resource Group to create.

.EXAMPLE
    PS C:\> .\create-resourcegroup.ps1 -ResourceGroupName MyResourceGroup
    This will create a new Resource Group named 'MyResourceGroup' in the 'centralus' location.


.NOTES
    Author: Mike Hagel 
    Date: 2026 AUG 23
    Course: PowerShell Advanced
#>
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[a-zA-Z0-9-_]+$')]
    [string]$ResourceGroupName
)
# Start logging script activity to a log file
Start-Transcript -Path ".\create-resourcegroup.log.txt"
Write-Verbose "Starting script to create resource group '$ResourceGroupName'."
Write-Debug "DebugPreference is set to $DebugPreference"

try {
    #Attempt to create the resource group 
    Write-Verbose "Attempting to create resource group '$ResourceGroupName' in 'centralus' location."
    Write-Debug "About to call New-AzResourceGroup with -ErrorAction Stop to ensure any errors are caught."
    New-AzResourceGroup -Name $ResourceGroupName -Location centralus -ErrorAction Stop
    Write-Output "Resource group '$ResourceGroupName' created successfully."
    Write-Verbose "Resource group creation completed without errors."
}
catch {
    #Handle any errors that occur during resource group creation
    Write-Output "Failed to create resource group '$ResourceGroupName'."
    Write-Output "Error: $($_.Exception.Message)"
}
finally {
    #Always stop the transcript to ensure logging is complete
    Write-Output "Script execution finished."
    Write-Verbose "Stopping transcript and exiting script."
    Write-Debug "Reached the end of the script execution block."
    Stop-Transcript
}
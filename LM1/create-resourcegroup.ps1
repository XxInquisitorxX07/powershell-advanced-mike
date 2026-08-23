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

try {
    #Attempt to create the resource group 
    New-AzResourceGroup -Name $ResourceGroupName -Location centralus -ErrorAction Stop
    Write-Output "Resource group '$ResourceGroupName' created successfully."
}
catch {
    #Handle any errors that occur during resource group creation
    Write-Output "Failed to create resource group '$ResourceGroupName'."
    Write-Output "Error: $($_.Exception.Message)"
}
finally {
    #Always stop the transcript to ensure logging is complete
    Write-Output "Script execution finished."
    Stop-Transcript
}
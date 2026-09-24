# NWTC.ResourceGroups.psm1
# Module entry point - loads every function file in the Public folder
# and exports only those functions.
# Author: Mike Hagel
# Course: PowerShell Advanced

# Find all .ps1 files in the Public folder.
# $PSScriptRoot = the folder this .psm1 lives in, so no path is hard-coded.
$publicFunctions = Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue

# Dot-source each file so its function is defined inside the module
foreach ($file in $publicFunctions) {
    try {
        . $file.FullName
    }
    catch {
        Write-Error "Failed to import function file '$($file.FullName)': $($_.Exception.Message)"
    }
}

# Export only the public functions.
# BaseName = file name without .ps1, so each file must be named after its function
# (New-TestResourceGroup.ps1 -> New-TestResourceGroup).
Export-ModuleMember -Function $publicFunctions.BaseName
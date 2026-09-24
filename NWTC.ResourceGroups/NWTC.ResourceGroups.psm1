# NWTC.ResourceGroups.psm1
# Module entry point - loads every function file in the Public folder.
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
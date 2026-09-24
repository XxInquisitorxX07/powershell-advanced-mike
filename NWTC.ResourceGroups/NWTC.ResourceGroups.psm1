# NWTC.ResourceGroups.psm1
# Module entry point - loads every function file in the Public and Private folders,
# then exports only the public functions.
# Author: Mike Hagel
# Course: PowerShell Advanced

# Find all .ps1 files in the Public and Private folders.
# $PSScriptRoot = the folder this .psm1 lives in, so no path is hard-coded.
$publicFunctions  = Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1"  -ErrorAction SilentlyContinue
$privateFunctions = Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue

# Dot-source each public function file
foreach ($file in $publicFunctions) {
    try {
        . $file.FullName
    }
    catch {
        Write-Error "Failed to import public function file '$($file.FullName)': $($_.Exception.Message)"
    }
}

# Dot-source each private function file
# These are loaded so public functions can call them, but they are NOT exported.
foreach ($file in $privateFunctions) {
    try {
        . $file.FullName
    }
    catch {
        Write-Error "Failed to import private function file '$($file.FullName)': $($_.Exception.Message)"
    }
}

# Export only the public functions.
# BaseName = file name without .ps1, so each file must be named after its function
# (New-TestResourceGroup.ps1 -> New-TestResourceGroup).
# Private functions are intentionally left out of this list.
Export-ModuleMember -Function $publicFunctions.BaseName
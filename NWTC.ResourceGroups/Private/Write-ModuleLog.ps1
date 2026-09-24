function Write-ModuleLog {
    <#
    .SYNOPSIS
        Writes a timestamped message to a log file.
    .DESCRIPTION
        Private helper for the NWTC.ResourceGroups module.
        Adds one line to the log file in the format:
            yyyy-MM-dd HH:mm:ss [LEVEL] Message
        Creates the log file, and its folder, if they don't exist yet.
        This function is not exported - only functions inside the module can call it.
    .PARAMETER Message
        The text to write to the log.
    .PARAMETER LogFile
        Full path to the log file. The file is created if it doesn't exist.
    .PARAMETER Level
        Severity of the message: INFO, WARN, or ERROR. Defaults to INFO.
    .EXAMPLE
        Write-ModuleLog -Message "Starting the creation of Resource Group..." -Level INFO -LogFile $logFile
        Adds: 2026-09-24 09:00:00 [INFO] Starting the creation of Resource Group...
    .EXAMPLE
        Write-ModuleLog -Message "Resource Group 'RG-1001' already exists." -Level WARN -LogFile $logFile
        Adds: 2026-09-24 09:00:01 [WARN] Resource Group 'RG-1001' already exists.
    .NOTES
        Author: Mike Hagel
        Date: 2026 Sep 24 - Created to replace Start-Transcript/Stop-Transcript in New-TestResourceGroup
        Course: PowerShell Advanced
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter(Mandatory)]
        [string]$LogFile,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    # Create the log folder if it doesn't exist yet
    $logFolder = Split-Path -Path $LogFile -Parent
    if ($logFolder -and -not (Test-Path -Path $logFolder)) {
        New-Item -ItemType Directory -Path $logFolder -Force -WhatIf:$false -Confirm:$false | Out-Null
    }

    # Build the log line: 2026-09-24 09:00:00 [INFO] Message
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line      = "$timestamp [$Level] $Message"

    # Add-Content creates the file on first write, then appends after that
    # -WhatIf:$false / -Confirm:$false - logging always happens, even during -WhatIf
    Add-Content -Path $LogFile -Value $line -WhatIf:$false -Confirm:$false
}
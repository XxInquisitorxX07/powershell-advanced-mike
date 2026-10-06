<#
    LM7 - Mike Hagel baseline configuration
    Applies the Cloud Operations Team server baseline to the local machine.

    Compile:  . .\DSC\lm7-dsc.ps1
              MikeHagelBaseline -OutputPath C:\powershell-advanced-mike\DSC\MikeHagelBaseline
    Apply:    Start-DscConfiguration -Path C:\powershell-advanced-mike\DSC\MikeHagelBaseline -Wait -Verbose
    Verify:   Test-DscConfiguration
#>

Configuration MikeHagelBaseline
{
    # Explicitly import the built-in resources (removes the warning the class example produced)
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node localhost
    {
        # Stamp the server with the baseline it was built from
        Registry BaselineVersion
        {
            Key       = 'HKEY_LOCAL_MACHINE\SOFTWARE\NWTC\Baseline'
            ValueName = 'BaselineVersion'
            ValueData = '1.0'
            ValueType = 'String'
            Ensure    = 'Present'
        }
    }
}
<#
    LM7 - Mike Hagel baseline configuration
    Applies the Cloud Operations Team server baseline to the local machine.

    Baseline history:
      1.0 - Registry stamp (HKLM\SOFTWARE\NWTC\Baseline\BaselineVersion)
      1.1 - Added Windows Time service (W32Time) running and set to Automatic

    Compile:  . .\DSC\lm7-dsc.ps1
              MikeHagelBaseline -OutputPath C:\powershell-advanced-mike\DSC\MikeHagelBaseline
    Apply:    Start-DscConfiguration -Path C:\powershell-advanced-mike\DSC\MikeHagelBaseline -Wait -Verbose -Force
    Verify:   Test-DscConfiguration -Detailed
#>

Configuration MikeHagelBaseline
{
    # Explicitly import the built-in resources (removes the warning the class example produced)
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node localhost
    {
        # Stamp the server with the baseline version it was built from
        Registry BaselineVersion
        {
            Key       = 'HKEY_LOCAL_MACHINE\SOFTWARE\NWTC\Baseline'
            ValueName = 'BaselineVersion'
            ValueData = '1.1'
            ValueType = 'String'
            Ensure    = 'Present'
        }

        # Accurate time is required for Kerberos authentication and for lining up log timestamps
        Service WindowsTime
        {
            Name        = 'W32Time'
            State       = 'Running'
            StartupType = 'Automatic'
        }
    }
}
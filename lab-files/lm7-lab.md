# LM7 Lab: Creating a Baseline Configuration with DSC

**Student:** Mike Hagel
**VM:** PA-mike
**Shell:** Windows PowerShell 5.1 (run as Administrator)

> DSC note: `Start-DscConfiguration`, `Test-DscConfiguration`, and `Get-DscConfiguration` are part of `PSDesiredStateConfiguration` 1.1, which ships with Windows PowerShell 5.1. In PowerShell 7 they showed up as version 1.0 functions, so all DSC work in this lab was run in 5.1 (started by typing `powershell` from the pwsh terminal).

---

## Task 1: Examine a DSC Configuration

Example file: `DSC/dsc-config-example.ps1` (from the class GitHub)

| Item | Value |
|---|---|
| Configuration name | `CompanyBaseline` |
| Node | `localhost` (the machine the configuration is applied to) |
| Resource 1 | `File AutomationFolder` |
| Resource 2 | `File ConfigFile` |

**What each resource does:**
- **AutomationFolder:** uses the built-in `File` resource with `Type = "Directory"` and `Ensure = "Present"` to make sure the folder `C:\Automation` exists.
- **ConfigFile:** uses the `File` resource with `Type = "File"` to make sure `C:\Automation\Config.txt` exists and contains exactly `NWTC Standard Configuration`. `DependsOn = "[File]AutomationFolder"` makes DSC create the folder first, so the file always has somewhere to go.

**Key idea:** the configuration doesn't say *how* to create anything. It says *what the end state should be*, and DSC figures out what (if anything) needs to change.


### Compile, Apply, Verify

**Compile:** dot-sourced the example, then called the configuration like a function:

    . .\DSC\dsc-config-example.ps1
    CompanyBaseline -OutputPath C:\powershell-advanced-mike\DSC\CompanyBaselineExample

Result: `DSC/CompanyBaselineExample/localhost.mof` (3,110 bytes). The compiler warned that the example loads built-in resources without `Import-DscResource -ModuleName PSDesiredStateConfiguration`; it still compiled.

The downloaded `.ps1` triggered a "Run only scripts that you trust" prompt because Windows marks downloaded files. Cleared it with `Unblock-File`.

**Apply:**

    Start-DscConfiguration -Path C:\powershell-advanced-mike\DSC\CompanyBaselineExample -Wait -Verbose

The lab says to point `-Path` at the MOF file, but `Start-DscConfiguration` takes the **folder** containing the MOF.

Verbose output showed the LCM process each resource as **Test → Set**. The Test phase reported "cannot find the file specified" because `C:\Automation` didn't exist yet, so the Set phase created it. Then the same for `Config.txt`. Completed in 1.17 seconds. A one-time warning about the meta configuration MOF appeared because the LCM had never been configured on this VM, so it used defaults.

**Verify:**

| Command | Result |
|---|---|
| `Test-DscConfiguration` | `True` |
| `Get-DscConfiguration` | Both resources `present`: `C:\Automation` (directory) and `C:\Automation\Config.txt` (file, 30 bytes) |
| `Get-Content C:\Automation\Config.txt` | `NWTC Standard Configuration` |


## Task 2: Create Your First DSC Configuration

Created `DSC/lm7-dsc.ps1` with configuration `MikeHagelBaseline`:

- `Import-DscResource -ModuleName PSDesiredStateConfiguration` loads the built-in resources explicitly. Best practice, and it removes the warning the class example produced.
- Node: `localhost`
- Resource: **`Registry BaselineVersion`**, a different resource type than the example's `File`. It ensures `HKEY_LOCAL_MACHINE\SOFTWARE\NWTC\Baseline` exists with a String value `BaselineVersion = 1.0`. This stamps the server with the baseline version it was built from, which an admin or audit can check.
- A comment header documents what the configuration does and the compile/apply/verify commands.

## Task 3: Generate and Review MOF Files

Compiled in Windows PowerShell 5.1:

    . .\DSC\lm7-dsc.ps1
    MikeHagelBaseline -OutputPath C:\powershell-advanced-mike\DSC\MikeHagelBaseline

No warning this time, because `Import-DscResource` was included.

| Item | Detail |
|---|---|
| **File location** | `C:\powershell-advanced-mike\DSC\MikeHagelBaseline\localhost.mof` (2,216 bytes). The file is named after the node. |
| **File purpose** | The compiled form of the configuration. The `.ps1` is the human-readable definition. The MOF is the standard document the Local Configuration Manager (LCM) actually reads and enforces. The LCM never sees the PowerShell code. |
| **Information observed** | A header with the target node (`localhost`), who generated it (`student`), when (10/05/2026 19:10:28), and on which host (`PA-mike`). One `instance of MSFT_RegistryResource` with `ResourceID = "[Registry]BaselineVersion"`, the key, value name, value type, `ValueData = {"1.0"}` (stored as an array), and `Ensure = "Present"`. `SourceInfo` points back to the exact line in `lm7-dsc.ps1` (line 19). An `OMI_ConfigurationDocument` block holds the configuration name and version metadata. |

Compared to the example MOF: the example had two `MSFT_FileDirectoryConfiguration` instances linked by `DependsOn`. Mine has one `MSFT_RegistryResource` instance. Same structure, different resource class.


## Task 4: Apply the Configuration

    Start-DscConfiguration -Path C:\powershell-advanced-mike\DSC\MikeHagelBaseline -Wait -Verbose -Force

`-Force` was used because `CompanyBaseline` was already the applied configuration.

**Results (from verbose output):**
- **Test:** `Registry key 'HKLM:\SOFTWARE\NWTC\Baseline' does not exist`. The system was out of compliance.
- **Set:** `Create registry key 'HKLM:\SOFTWARE\NWTC\Baseline'`, then `Set registry key value ... BaselineVersion to '1.0' of type 'String'`.
- Completed in 1.71 seconds with no errors or warnings. The Task 1 meta-configuration warning did not appear again.

**Independent check:** not relying only on DSC's own report.

| Command | Result |
|---|---|
| `Get-ItemProperty -Path 'HKLM:\SOFTWARE\NWTC\Baseline' -Name BaselineVersion` | `BaselineVersion : 1.0` |
| `Test-Path C:\Automation\Config.txt` | `True` |

**Observation:** the LCM holds one current configuration at a time. Applying `MikeHagelBaseline` replaced `CompanyBaseline`, but DSC did not delete `C:\Automation` or `Config.txt`. It simply stopped tracking them. A new configuration replaces what DSC *monitors*, not what exists on the machine. To keep the example's resources enforced, they would need to be part of the same configuration.


## Task 5: Validate Compliance

| Command | Result |
|---|---|
| `Test-DscConfiguration` | `True` |
| `Get-DscConfiguration` | `MikeHagelBaseline`: `[Registry]BaselineVersion`, key `HKLM:\SOFTWARE\NWTC\Baseline`, `ValueData {1.0}`, `ValueType String`, `Ensure Present` |

### Drift Test (extra)

To see DSC detect and correct configuration drift, I changed the setting by hand, the way an admin might on a live server:

    Set-ItemProperty -Path 'HKLM:\SOFTWARE\NWTC\Baseline' -Name BaselineVersion -Value '0.9'

| Step | Command | Result |
|---|---|---|
| Detect | `Test-DscConfiguration -Detailed` | `InDesiredState: False`, `ResourcesNotInDesiredState: {[Registry]BaselineVersion}` |
| Correct | `Start-DscConfiguration -UseExisting -Wait -Verbose` | Test: `does not contain data '1.0'`, then Set: `Set registry key value ... to '1.0'`. Completed in 0.48 seconds |
| Confirm | `Test-DscConfiguration` / `Get-ItemProperty` | `True` / `BaselineVersion : 1.0` |

`-UseExisting` re-applies the configuration the LCM already holds, with no recompile. DSC only changed the one setting that had drifted.
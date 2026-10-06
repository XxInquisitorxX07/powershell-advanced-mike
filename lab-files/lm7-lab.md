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
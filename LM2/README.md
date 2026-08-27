# LM2: Testing, Debugging, and Source Control
## Project Purpose
This project contains a PowerShell script that creates an Azure resource group with parameter validation and error handling. LM2 added verbose and debug output for visibility, an automated Pester test to verify the group is created, and version control through GitHub.
## Files Included
- `LM1/create-resourcegroup.ps1` — Creates ResourceGroups with proper naming, and runs a verbose that will show what it is doing. Runs with a debug to show where issues may be.
- `LM1/create-resourcegroup.log.txt` — Log file of what was created with proper documentation of creation date and time as well as name and information of versions and software.
- `LM2/create-resourcegroup.tests.ps1` — This is to verify that the script created a resource group and queries Azure to confirm the group exists.
- `LM2/lm2-lab.md` — Gives detailed documentation of scripting and detailed information on any errors and the fixes that took place to ensure it worked.
- `LM2/README.md` — File to give overview of what is documented.
## Lessons Learned
Learned that running Verbose and Debugging helps ensure a script will work as intended without causing downtime in the future.

Ran into a tenant mismatch. Signing in worked and I had Owner permissions on the subscription, but I was signing into the wrong directory. Azure reported it as a permissions error, which pointed me in the wrong direction at first.

When running the Pester segment it passed but waited for user input, since I ran it prior and it was waiting for authorization to replace the already created group. A test that waits for someone to press a key cannot run unattended, which defeats part of the purpose of automated testing.
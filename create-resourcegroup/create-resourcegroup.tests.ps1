<#
.SYNOPSIS
    Pester tests for the New-TestResourceGroup function.
.DESCRIPTION
    Tests both parameter sets, pipeline input, the skip check for existing groups,
    error handling, -WhatIf, parameter validation, and output shape.
    Azure cmdlets are mocked, so no real resources are created.
.NOTES
    Author: Mike Hagel
    Date: 2026 Sep 17 - Rewritten to test the LM4 advanced function
    Course: PowerShell Advanced
    Run with: Invoke-Pester .\create-resourcegroup\create-resourcegroup.tests.ps1 -Output Detailed
#>

BeforeAll {
    # Load the function into the test session
    . (Join-Path $PSScriptRoot 'create-resourcegroup.ps1')
}

Describe 'New-TestResourceGroup' {

    BeforeAll {
        # Keep the log file and screen clean during tests
        Mock Start-Transcript { }
        Mock Stop-Transcript { }
        Mock Write-Host { }

        # Default: no resource group exists yet, and creation succeeds
        Mock Get-AzResourceGroup { $null }
        Mock New-AzResourceGroup { [PSCustomObject]@{ ResourceGroupName = $Name } }
    }

    Context 'Parameter sets' {

            It 'Builds the name RG-{ProjectID} when -ProjectID is used' {
            $result = New-TestResourceGroup -ProjectID 1001

            $result.ResourceGroupName | Should -Be 'RG-1001'
            $result.Status            | Should -Be 'Created'
            Should -Invoke New-AzResourceGroup -Times 1 -Exactly -ParameterFilter { $Name -eq 'RG-1001' }
        }

        It 'Uses the name as-is when -ResourceGroupName is used' {
            $result = New-TestResourceGroup -ResourceGroupName 'Dev1'

            $result.ResourceGroupName | Should -Be 'Dev1'
            $result.Status            | Should -Be 'Created'
            Should -Invoke New-AzResourceGroup -Times 1 -Exactly -ParameterFilter { $Name -eq 'Dev1' }
        }

        It 'Rejects -ProjectID and -ResourceGroupName used together' {
            { New-TestResourceGroup -ProjectID 1001 -ResourceGroupName 'Dev1' } | Should -Throw
        }
    }

    Context 'Pipeline input' {

        It 'Creates one resource group for each piped ProjectID' {
            $results = '1001', '1002', '1003' | New-TestResourceGroup

            $results.Count | Should -Be 3
            $results.ResourceGroupName | Should -Be @('RG-1001', 'RG-1002', 'RG-1003')
            Should -Invoke New-AzResourceGroup -Times 3 -Exactly
        }

        It 'Returns only result objects (no stray strings in the output)' {
            $results = '1001', '1002' | New-TestResourceGroup

            # Guards against the Task 5 bug where transcript text leaked into the output
            $results | Where-Object { $_ -is [string] } | Should -BeNullOrEmpty
            $results | ForEach-Object { $_.PSObject.Properties.Name | Should -Contain 'Status' }
        }
    }

    Context 'Skip, error, and WhatIf handling' {

        It 'Skips a resource group that already exists' {
            Mock Get-AzResourceGroup { [PSCustomObject]@{ ResourceGroupName = 'RG-2001' } } -ParameterFilter { $Name -eq 'RG-2001' }

            $result = New-TestResourceGroup -ProjectID 2001 -WarningAction SilentlyContinue

            $result.Status | Should -Be 'Skipped'
            Should -Invoke New-AzResourceGroup -Times 0 -Exactly
        }

        It 'Marks the result as Failed when Azure returns an error' {
            Mock New-AzResourceGroup { throw 'Simulated Azure failure' }

            $result = New-TestResourceGroup -ProjectID 3001 -WarningAction SilentlyContinue

            $result.Status | Should -Be 'Failed'
        }

        It 'Does not create anything when -WhatIf is used' {
            $result = New-TestResourceGroup -ProjectID 4001 -WhatIf

            $result.Status | Should -Be 'Skipped'
            Should -Invoke New-AzResourceGroup -Times 0 -Exactly
        }
    }

    Context 'Validation' {

        It 'Rejects a ProjectID that is not all digits' {
            { New-TestResourceGroup -ProjectID 'abc' } | Should -Throw
        }

        It 'Rejects a ResourceGroupName with invalid characters' {
            { New-TestResourceGroup -ResourceGroupName 'bad name!' } | Should -Throw
        }
    }
}
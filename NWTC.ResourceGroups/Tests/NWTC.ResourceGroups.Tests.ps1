BeforeAll {
    $manifestPath = Join-Path $PSScriptRoot '..\NWTC.ResourceGroups.psd1'
    Import-Module $manifestPath -Force
}

AfterAll {
    Remove-Module NWTC.ResourceGroups -ErrorAction SilentlyContinue
}

Describe 'NWTC.ResourceGroups module' {

    It 'has a valid manifest' {
        { Test-ModuleManifest -Path $manifestPath -ErrorAction Stop } | Should -Not -Throw
    }

    It 'is version 1.1.0' {
        (Test-ModuleManifest -Path $manifestPath).Version.ToString() | Should -Be '1.1.0'
    }

    It 'exports New-TestResourceGroup' {
        (Get-Command -Module NWTC.ResourceGroups).Name | Should -Contain 'New-TestResourceGroup'
    }

    It 'exports Get-ResourceGroupSummary' {
        (Get-Command -Module NWTC.ResourceGroups).Name | Should -Contain 'Get-ResourceGroupSummary'
    }

    It 'keeps Write-ModuleLog private' {
        (Get-Command -Module NWTC.ResourceGroups).Name | Should -Not -Contain 'Write-ModuleLog'
    }

    It 'has comment-based help for Get-ResourceGroupSummary' {
        (Get-Help Get-ResourceGroupSummary).Synopsis | Should -Match 'summary'
    }
}

Describe 'Get-ResourceGroupSummary' {

    BeforeAll {
        # Default mock: two resource groups, one tagged and one not
        Mock -ModuleName NWTC.ResourceGroups -CommandName Get-AzResourceGroup -MockWith {
            [PSCustomObject]@{ ResourceGroupName = 'RG-1001'; Location = 'centralus'; Tags = @{ Project = '1001'; Env = 'Lab' } }
            [PSCustomObject]@{ ResourceGroupName = 'Dev1';    Location = 'centralus'; Tags = $null }
        }

        # Lookup by a specific name
        Mock -ModuleName NWTC.ResourceGroups -CommandName Get-AzResourceGroup -ParameterFilter { $Name -eq 'RG-1001' } -MockWith {
            [PSCustomObject]@{ ResourceGroupName = 'RG-1001'; Location = 'centralus'; Tags = @{ Project = '1001'; Env = 'Lab' } }
        }

        # A group that does not exist
        Mock -ModuleName NWTC.ResourceGroups -CommandName Get-AzResourceGroup -ParameterFilter { $Name -eq 'Missing-RG' } -MockWith {
            throw 'Provided resource group does not exist.'
        }
    }

    It 'returns every group when no name is given' {
        @(Get-ResourceGroupSummary).Count | Should -Be 2
    }

    It 'returns only name, location, and tags' {
        $result = Get-ResourceGroupSummary -Name 'RG-1001'
        $result.PSObject.Properties.Name | Should -Be @('ResourceGroupName', 'Location', 'Tags')
    }

    It 'formats tags as sorted Key=Value pairs' {
        (Get-ResourceGroupSummary -Name 'RG-1001').Tags | Should -Be 'Env=Lab; Project=1001'
    }

    It 'shows None for a group with no tags' {
        (Get-ResourceGroupSummary | Where-Object ResourceGroupName -eq 'Dev1').Tags | Should -Be 'None'
    }

    It 'accepts names from the pipeline' {
        $result = 'RG-1001' | Get-ResourceGroupSummary
        $result.ResourceGroupName | Should -Be 'RG-1001'
        Should -Invoke -ModuleName NWTC.ResourceGroups -CommandName Get-AzResourceGroup -Times 1 -Exactly
    }

    It 'accepts objects with a ResourceGroupName property from the pipeline' {
        $result = [PSCustomObject]@{ ResourceGroupName = 'RG-1001' } | Get-ResourceGroupSummary
        $result.Location | Should -Be 'centralus'
    }

    It 'warns and keeps going when a group is not found' {
        $result = Get-ResourceGroupSummary -Name 'Missing-RG', 'RG-1001' -WarningVariable warn -WarningAction SilentlyContinue
        @($result).Count | Should -Be 1
        $warn.Count | Should -Be 1
        $warn[0] | Should -Match 'Missing-RG'
    }
}
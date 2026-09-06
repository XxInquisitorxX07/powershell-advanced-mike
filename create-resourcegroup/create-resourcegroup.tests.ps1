Describe "create-resourcegroup.ps1" {
    It "Creates the resource group in Azure" {
        $rgName = "PesterTestRG"
        & "$PSScriptRoot\..\LM1\create-resourcegroup.ps1" -ResourceGroupName $rgName
        $rg = Get-AzResourceGroup -Name $rgName
        $rg.ResourceGroupName | Should -Be $rgName
    }
}
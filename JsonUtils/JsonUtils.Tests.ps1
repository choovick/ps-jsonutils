
Import-Module $PSScriptRoot\JsonUtils.psm1 -Force

Describe "JsonUtils" {

    It "Simple JSON test" {

        $From = (Get-Content -Path "$PSScriptRoot/test-from.json" -Raw)
        $To = (Get-Content -Path "$PSScriptRoot/test-to.json" -Raw)
        $ExpectedResult = (Get-Content -Path "$PSScriptRoot/test-result.json" -Raw)

        Get-JsonDifference -FromJsonString $From -ToJsonString $To -Compress `
        | Should -BeExactly $ExpectedResult
    }

    It "Invalid FromJsonString int test" {
        {
            Get-JsonDifference `
                -FromJsonString '1' `
                -ToJsonString '{"valid":"input"}'
        } | Should -Throw "FromJsonString must be an object at the root"
    }

    It "Invalid FromJsonString null test" {
        {
            Get-JsonDifference `
                -FromJsonString 'null' `
                -ToJsonString '{"valid":"input"}'
        } | Should -Throw "FromJsonString must be an object at the root"
    }

    It "Invalid ToString null test" {
        {
            Get-JsonDifference `
                -FromJsonString '{"valid":"input"}' `
                -ToJsonString 'null'
        } | Should -Throw "ToJsonString must be an object at the root"
    }

    It "Invalid ToString string test" {
        {
            Get-JsonDifference `
                -FromJsonString '{"valid":"input"}' `
                -ToJsonString '"string"'
        } | Should -Throw "ToJsonString must be an object at the root"
    }

    It "SortTest" {
        ConvertTo-KeysSortedJSONString -JsonString  (Get-Content -Path "$PSScriptRoot/test-result.json" -Raw) -Compress `
        | Should -BeExactly (Get-Content -Path "$PSScriptRoot/test-result-sorted.json" -Raw)
    }
    
    It "SortTest pipeline" {
        Get-Content -Path "$PSScriptRoot/test-result.json" -Raw | ConvertTo-KeysSortedJSONString -Compress `
        | Should -BeExactly (Get-Content -Path "$PSScriptRoot/test-result-sorted.json" -Raw)
    }
}

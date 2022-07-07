
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
        ConvertTo-KeysSortedJSONString -JsonString (Get-Content -Path "$PSScriptRoot/test-result.json" -Raw) -Compress `
        | Should -BeExactly (Get-Content -Path "$PSScriptRoot/test-result-sorted.json" -Raw)
    }
    It "SortTest array" {
        $string = Get-Content -Path "$PSScriptRoot/test-result.json" -Raw
        ConvertTo-KeysSortedJSONString -JsonString ($string, $string) -Compress `
        | ForEach-Object { $_ | Should -BeExactly (Get-Content -Path "$PSScriptRoot/test-result-sorted.json" -Raw) }
    }

    It "SortTest pipeline" {
        Get-Content -Path "$PSScriptRoot/test-result.json" -Raw | ConvertTo-KeysSortedJSONString -Compress `
        | Should -BeExactly (Get-Content -Path "$PSScriptRoot/test-result-sorted.json" -Raw)
    }

    It "SortTest" {
        Convert-JsonKeysToSorted -JsonString (Get-Content -Path "$PSScriptRoot/test-result.json" -Raw) -Compress `
        | Should -BeExactly (Get-Content -Path "$PSScriptRoot/test-result-sorted.json" -Raw)
    }
    It "SortTest single items" {
        Convert-JsonKeysToSorted -JsonString '{"b":1,"1":[{"b":null,"a":1}]}' -Compress `
        | Should -BeExactly '{"1":[{"a":1,"b":null}],"b":1}'
    }
    It "SortTest single array" {
        Convert-JsonKeysToSorted -JsonString '[{"b":1,"1":[{"b":null,"a":1}]}]' -Compress `
        | Should -BeExactly '[{"1":[{"a":1,"b":null}],"b":1}]'
    }

    It "SortTest array" {
        $string = Get-Content -Path "$PSScriptRoot/test-result.json" -Raw
        Convert-JsonKeysToSorted -JsonString ($string, $string) -Compress `
        | ForEach-Object { $_ | Should -BeExactly (Get-Content -Path "$PSScriptRoot/test-result-sorted.json" -Raw) }
    }

    It "SortTest pipeline" {
        Get-Content -Path "$PSScriptRoot/test-result.json" -Raw | Convert-JsonKeysToSorted -Compress `
        | Should -BeExactly (Get-Content -Path "$PSScriptRoot/test-result-sorted.json" -Raw)
    }

    It "SortTest as object" {
        Convert-JsonKeysToSorted -InputObject (Get-Content -Path "$PSScriptRoot/test-result.json" | ConvertFrom-Json) -Compress `
        | Should -BeExactly (Get-Content -Path "$PSScriptRoot/test-result-sorted.json" -Raw)
    }

    It "SortTest as object via pipeline" {
        Get-Item -Path "$PSScriptRoot/test-result.json" | Select-Object Name, Length | Convert-JsonKeysToSorted -Compress `
        | Should -BeExactly (Get-Item -Path "$PSScriptRoot/test-result.json" | Select-Object Length, Name | ConvertTo-Json -Compress)
    }
}
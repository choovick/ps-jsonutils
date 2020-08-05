<#
# Install Pester:
Install-Module Pester -MinimumVersion 5.0.2 -Scope CurrentUser -Force


# Code coverage in VSCode plugin:
code --install-extension ryanluker.vscode-coverage-gutters

# Run this script to execute  test against tests files ending on "something.Tests.ps1"
#>
$ErrorActionPreference = "Stop"

Import-Module Pester -MinimumVersion 5.0.2 -Force

$Configuration = [PesterConfiguration]::Default
# Add files here what require code coverage
$Configuration.Run.Path = $PSScriptRoot
$Configuration.CodeCoverage.Path = @(("$PSScriptRoot/JsonUtils/*.psm1"))
$Configuration.CodeCoverage.OutputPath = "$PSScriptRoot/cov.xml"
$Configuration.CodeCoverage.Enabled = $true

Invoke-Pester -Configuration $Configuration
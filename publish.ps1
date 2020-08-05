[CmdletBinding()]
param (
    [Parameter(Mandatory = 1)][string]$NuGetApiKey,
    [switch]$Force
)

Publish-Module -NuGetApiKey $NuGetApiKey -Path "$PSScriptRoot/JsonUtils" -Repository "PSGallery" -Force:$Force
# Type name representing null
$Script:NullType = "NullType"

function Get-JsonDifference
{
    <#
    .SYNOPSIS
        Compares two JSON strings and generated stringified JSON object representing differences.

        LIMITATIONS:
            1. Arrays sub-objects are compared literally as strings after every object within array is sorted by keys and
                whole array is minified afterwards.

            2. Due to limitation of ConvertTo-Json in PowerShell 5.1 <https://github.com/PowerShell/PowerShell/issues/3705>
                object with case sensitive keys are not supported. E.g. Can't have object wil `KeyName` and `keyname`.

    .PARAMETER FromJsonString
        Old variant of stringified JSON object.

    .PARAMETER ToJsonString
        New variant of stringified JSON object that FromJsonString will be compared to.

    .PARAMETER Depth
        Depth used on resulting object conversion to JSON string ('ConvertTo-Json -Depth' parameter).
        Is it also used when converting Array values into JSON string after it has been sorted for comparison logic.

    .PARAMETER Compress
        Set to minify resulting object

    .OUTPUTS
        JSON string with the following JSON object keys:
        - Added - items that were not present in FromJsonString and are now in ToJsonString JSON object.
        - Changed - items that were present in FromJsonString and in ToJsonString containing new values are from ToJsonString JSON object.
        - ChangedOriginals - - items that were present in FromJsonString and in ToJsonString containing old values are from FromJsonString JSON object.
        - Removed - items that were present in FromJsonString and are missing in ToJsonString JSON object.
        - NotChanged - items that are present in FromJsonString and in ToJsonString JSON objects with the same values.
        - New - Merged Added and Changed resulting objects representing all items that have changed and were added.

    .EXAMPLE
        Get-JsonDifference -FromJsonString '{"foo_gone":"bar","bar":{"foo":"bar","bar":"foo"},"arr":[{"bar":"baz","foo":"bar"},1]}' `
                           -ToJsonString   '{"foo_added":"bar","bar":{"foo":"bar","bar":"baz"},"arr":[{"foo":"bar","bar":"baz"},1]}'
        {
            "Added": {
                "foo_added": "bar"
            },
            "Changed": {
                "bar": {
                    "bar": "baz"
                }
            },
            "ChangedOriginals": {
                "bar": {
                    "bar": "foo"
                }
            },
            "Removed": {
                "foo_gone": "bar"
            },
            "NotChanged": {
                "bar": {
                        "foo": "bar"
                },
                "arr": [
                    {
                        "foo": "bar",
                        "bar": "baz"
                    },
                    1
                ]
            },
            "New": {
                "foo_added": "bar",
                "bar": {
                    "bar": "baz"
                }
            }
        }

    .LINK
        https://github.com/choovick/ps-jsonutils

    #>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Mandatory = $true)]
        [String]$FromJsonString,
        [Parameter(Mandatory = $true)]
        [String]$ToJsonString,
        [Parameter(Mandatory = $false)]
        [String]$Depth = 25,
        [Switch]$Compress
    )
    try
    {
        # Convert to PSCustomObjects
        $FromObject = ConvertFrom-Json -InputObject $FromJsonString
        $ToObject = ConvertFrom-Json -InputObject $ToJsonString
        # Ensuring both inputs are objects
        try
        {
            if (([PSCustomObject]@{ }).GetType() -ne $FromObject.GetType())
            {
                throw
            }
        }
        catch
        {
            throw "FromJsonString must be an object at the root"
        }
        try
        {
            if (([PSCustomObject]@{ }).GetType() -ne $ToObject.GetType())
            {
                throw
            }
        }
        catch
        {
            throw "ToJsonString must be an object at the root"
        }

        return Get-JsonDifferenceRecursion -FromObject $FromObject -ToObject $ToObject | ConvertTo-Json -Depth $Depth -Compress:$Compress

    }
    catch
    {
        throw
    }

}


function Get-JsonDifferenceRecursion
{
    <#
    .SYNOPSIS
        INTERNAL - Compares two PSCustomObjects produced via ConvertFrom-Json cmdlet.

    .PARAMETER FromObject
        Old variant of JSON object.

    .PARAMETER ToObject
        New variant of JSON object.

    .PARAMETER Depth
        Depth used when converting Array values into JSON string after it has been sorted for comparison logic.

    .OUTPUTS
        PSCustomObject with the following object keys:
        - Added - items that were not present in FromJsonString and are now in ToJsonString JSON object.
        - Changed - items that were present in FromJsonString and in ToJsonString containing new values are from ToJsonString JSON object.
        - ChangedOriginals - - items that were present in FromJsonString and in ToJsonString containing old values are from FromJsonString JSON object.
        - Removed - items that were present in FromJsonString and are missing in ToJsonString JSON object.
        - NotChanged - items that are present in FromJsonString and in ToJsonString JSON objects with the same values.
        - New - Merged Added and Changed resulting objects representing all items that have changed and were added.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        $FromObject,
        $ToObject,
        $Depth = 25
    )
    try
    {
        $Removed = [PSCustomObject]@{ }
        $Changed = [PSCustomObject]@{ }
        $ChangedOriginals = [PSCustomObject]@{ }
        $Added = [PSCustomObject]@{ }
        $New = [PSCustomObject]@{ }
        $NotChanged = [PSCustomObject]@{ }

        # Now for sort can capture each value of input object
        foreach ($Property in $ToObject.PsObject.Properties)
        {
            # Access the name of the property
            $ToName = $Property.Name
            # Access the value of the property
            $ToValue = $Property.Value

            # getting types handling null
            if ($null -eq $ToValue)
            {
                $ToValueType = $Script:NullType
            }
            else
            {
                $ToValueType = $ToValue.GetType()
            }

            # check if property exists in FromObject (in PS 5.1 we cant support case sensitive keys https://github.com/PowerShell/PowerShell/issues/3705)
            if ([bool]($FromObject.PSObject.Properties.Name -match [System.Text.RegularExpressions.Regex]::Escape($ToName)))
            {
                # old value
                $FromValue = $FromObject.$ToName

                # getting from object type
                # getting types handling null
                if ($null -eq $FromObject.$ToName)
                {
                    $FromValueType = $Script:NullType
                }
                else
                {
                    $FromValueType = $FromObject.$ToName.GetType()
                }

                # if both of them are object, continue recursion
                if ($FromValueType -eq ([PSCustomObject]@{ }).GetType() -and $ToValueType -eq ([PSCustomObject]@{ }).GetType())
                {
                    $Result = Get-JsonDifferenceRecursion -FromObject $FromValue -ToObject $ToValue
                    # capture differences
                    if (-not [string]::IsNullOrWhiteSpace($Result.Added))
                    {
                        Add-Member -InputObject $Added -MemberType NoteProperty -Name $ToName -Value $Result.Added
                    }
                    if (-not [string]::IsNullOrWhiteSpace($Result.Removed))
                    {
                        Add-Member -InputObject $Removed -MemberType NoteProperty -Name $ToName -Value $Result.Removed
                    }
                    if (-not [string]::IsNullOrWhiteSpace($Result.Changed))
                    {
                        Add-Member -InputObject $Changed -MemberType NoteProperty -Name $ToName -Value $Result.Changed
                    }
                    if (-not [string]::IsNullOrWhiteSpace($Result.ChangedOriginals))
                    {
                        Add-Member -InputObject $ChangedOriginals -MemberType NoteProperty -Name $ToName -Value $Result.ChangedOriginals
                    }
                    if (-not [string]::IsNullOrWhiteSpace($Result.NotChanged))
                    {
                        Add-Member -InputObject $NotChanged -MemberType NoteProperty -Name $ToName -Value $Result.NotChanged
                    }
                    if (-not [string]::IsNullOrWhiteSpace($Result.New))
                    {
                        Add-Member -InputObject $New -MemberType NoteProperty -Name $ToName -Value $Result.New
                    }
                }
                # if type is different
                elseif ($FromValueType -ne $ToValueType)
                {
                    # capturing new value in changed object
                    Add-Member -InputObject $Changed -MemberType NoteProperty -Name $ToName -Value $ToValue
                    Add-Member -InputObject $New -MemberType NoteProperty -Name $ToName -Value $ToValue
                    Add-Member -InputObject $ChangedOriginals -MemberType NoteProperty -Name $ToName -Value $FromValue
                }
                # If both are arrays, items should be sorted by now, so we will stringify them and compare as string case sensitively
                elseif ($FromValueType -eq @().GetType() -and $ToValueType -eq @().GetType())
                {
                    # stringify array
                    $FromJSON = Get-SortedPSCustomObjectRecursion $FromObject.$ToName | ConvertTo-Json -Depth $Depth
                    $ToJSON = Get-SortedPSCustomObjectRecursion $ToObject.$ToName | ConvertTo-Json -Depth $Depth

                    # add to changed object if values are different for stringified array
                    if ($FromJSON -cne $ToJSON)
                    {
                        Add-Member -InputObject $Changed -MemberType NoteProperty -Name $ToName -Value $ToValue
                        Add-Member -InputObject $New -MemberType NoteProperty -Name $ToName -Value $ToValue
                        Add-Member -InputObject $ChangedOriginals -MemberType NoteProperty -Name $ToName -Value $FromValue
                    }
                    else
                    {
                        Add-Member -InputObject $NotChanged -MemberType NoteProperty -Name $ToName -Value $ToValue
                    }
                }
                # other primitive types changes
                else
                {
                    if ($FromValue -cne $ToValue)
                    {
                        Add-Member -InputObject $Changed -MemberType NoteProperty -Name $ToName -Value $ToValue
                        Add-Member -InputObject $New -MemberType NoteProperty -Name $ToName -Value $ToValue
                        Add-Member -InputObject $ChangedOriginals -MemberType NoteProperty -Name $ToName -Value $FromValue
                    }
                    else
                    {
                        Add-Member -InputObject $NotChanged -MemberType NoteProperty -Name $ToName -Value $ToValue
                    }
                }
            }
            # if value does not exist in the from object, then its was added
            elseif (-not [bool]($FromObject.PSObject.Properties.Name -match [System.Text.RegularExpressions.Regex]::Escape($ToName)))
            {
                Add-Member -InputObject $Added -MemberType NoteProperty -Name $ToName -Value $ToValue
                Add-Member -InputObject $New -MemberType NoteProperty -Name $ToName -Value $ToValue
            }
        }

        # Looping from object to find removed items
        foreach ($Property in $FromObject.PsObject.Properties)
        {
            # Access the name of the property
            $FromName = $Property.Name
            # Access the value of the property
            $FromValue = $Property.Value

            # if property not on to object, its removed
            if (-not [bool]($ToObject.PSObject.Properties.Name -match [System.Text.RegularExpressions.Regex]::Escape($FromName)))
            {
                Add-Member -InputObject $Removed -MemberType NoteProperty -Name $FromName -Value $FromValue
            }
        }

        return [PSCustomObject]@{
            Added            = $Added
            Changed          = $Changed
            ChangedOriginals = $ChangedOriginals
            Removed          = $Removed
            NotChanged       = $NotChanged
            New              = $New
        }
    }
    catch
    {
        throw
    }
}

function ConvertTo-KeysSortedJSONString
{
    <#
    .SYNOPSIS
        Sorts JSON strings by object keys.

    .PARAMETER JsonString
        Input JSON string

    .PARAMETER Depth
        Used for ConvertTo-Json on resulting object

    .PARAMETER Compress
        Returned minified JSON

    .OUTPUTS
        String of sorted and stringified JSON object

    .EXAMPLE
        Convert-JsonKeysToSorted -JsonString '{"b":1,"1":{"b":null,"a":1}}'
        {
            "1": {
                "a": 1,
                "b": null
            },
            "b": 1
        }

    .EXAMPLE
        '{"b":1,"1":{"b":null,"a":1}}' | Convert-JsonKeysToSorted
        {
            "1": {
                "a": 1,
                "b": null
            },
            "b": 1
        }

    .LINK
        https://github.com/choovick/ps-jsonutils

    #>
    [CmdletBinding()]
    [Alias("Convert-JsonKeysToSorted")]
    [OutputType([String])]
    param(
        [Alias("JsonString")]
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        $InputObject,
        [Parameter(Mandatory = $false)]
        [String]$Depth = 25,
        [Switch]$Compress
    )
    begin
    {
        if ($MyInvocation.InvocationName -eq "ConvertTo-KeysSortedJSONString")
        {
            Write-Warning "DEPRECATED: Use Convert-JsonKeysToSorted instead of ConvertTo-KeysSortedJSONString. ConvertTo-KeysSortedJSONString may be removed in a future release"
        }
    }

    process
    {
        try
        {
            foreach ($item in $InputObject)
            {
                if ($item -is [string])
                {
                    $item = ConvertFrom-Json -InputObject $item -NoEnumerate
                }
                $ResultObject = Get-SortedPSCustomObjectRecursion -InputObject $item
                ConvertTo-Json -Compress:$Compress -Depth $Depth -InputObject $ResultObject
            }
        }
        catch
        {
            throw
        }
    }
}

function Get-SortedPSCustomObjectRecursion
{
    <#
    .SYNOPSIS
        INTERNAL - Recursion to sort PSCustomObject produced via ConvertFrom-Json by keys.
        Can take $null, that will be simply returned.

    .PARAMETER InputObject
        PSCustomObject produced via ConvertFrom-Json

    .OUTPUTS
        PSCustomObject sorted by keys

    #>
    [CmdletBinding()]
    [OutputType([Object])]
    param(
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$InputObject
    )

    # Use the Unary Comma operator on returns to ensure that arrays with only 1 item dont get unrolled/flattened/enumerated:
    # https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators#comma-operator-

    try
    {
        # null handle
        if ($null -eq $InputObject)
        {
            return , $InputObject
        }

        # object
        elseif ($InputObject.GetType() -eq ([PSCustomObject]@{ }).GetType())
        {
            # soft object by keys
            # thanks to https://stackoverflow.com/a/44056862/2174835
            $SortedInputObject = New-Object PSCustomObject
            $InputObject |
            Get-Member -Type NoteProperty | Sort-Object Name | ForEach-Object {
                Add-Member -InputObject $SortedInputObject -Type NoteProperty `
                    -Name $_.Name -Value $InputObject.$($_.Name)
            }

            # Now for sort can capture each value of input object
            foreach ($Property in $SortedInputObject.PsObject.Properties)
            {
                # Access the name of the property
                $PropertyName = $Property.Name
                # Access the value of the property
                $PropertyValue = $Property.Value

                $SortedInputObject.$PropertyName = Get-SortedPSCustomObjectRecursion -InputObject $PropertyValue
            }

            return , $SortedInputObject
        }

        # array, sort each item within array
        elseif ($InputObject.GetType() -eq @().GetType())
        {
            $SortedArrayObjects = @()

            foreach ($Item in $InputObject)
            {
                $SortedArrayObjects += @(Get-SortedPSCustomObjectRecursion -InputObject $Item)
            }

            return , $SortedArrayObjects
        }

        # primitive are not sorted as returned as is
        else
        {
            return , $InputObject
        }
    }
    catch
    {
        throw
    }
}